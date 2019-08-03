module Workers
  class ProcessEmployeeRows
    include Sidekiq::Worker
    sidekiq_options queue: 'employee_upload', retry: true, backtrace: true

    #TODO: Clean validation and creation flow
    def perform(*args)

      file_upload_id = args[0]
      row_start = args[1]
      row_end = args[2]
      validate_only = args[3]

      file_upload = FileUpload.find_by_id(file_upload_id)

      if file_upload.blank?
        Rails.logger.error("[Workers::ProcessEmployeeRows] Invalid file upload id - #{file_upload_id}")
        return
      end

      company_id = file_upload.attachable_id

      rows = CSV.parse(file_upload.data_file.download, headers: true)
      process_rows = rows[row_start..(row_end - 1)]

      total_rows = process_rows.count
      valid_rows = []
      errors = []
      row_count = row_start
      policies = []
      emails = []
      existing_emails = []

      #Process employee table data
      process_rows.each_with_index do |row, index|
        name = row["Employee Name"].to_s.strip
        email = row["Email"].to_s.strip
        phone = row["Phone"].to_s.strip
        emails << email

        employee_obj = Employee.new(name: name, email: email, phone: phone, company_id: company_id)

        if employee_obj.valid?
          valid_rows << employee_obj unless validate_only
        else
          errors << "Row #{row_count + 1} Error: #{employee_obj.errors.full_messages}"
        end

        row_count += 1

        #Bulk insert when INSERT threshold is reached or last row is in process
        if valid_rows.present? && (valid_rows.count == Employee::BULK_INSERT_SIZE || index == total_rows - 1)
          #Bulk SQL insert. No need for model validation. And ignore(don't raise exception) on duplicate emails
          Employee.import valid_rows, validate: false, on_duplicate_key_ignore: true
          valid_rows = []
        end

        #To validate existing emails in sheet
        if validate_only && emails.present? && (emails.count == Employee::BULK_INSERT_SIZE || index == total_rows - 1)
          existing_emails << Employee.where(email: emails).pluck(:email)
        end

        policies << row["Assigned Policies"].to_s.split("|").map(&:strip)
      end

      existing_emails = existing_emails.flatten
      if existing_emails.present?
        errors << "Error: Emails #{existing_emails.join(", ")} already exist in system"
      end

      #Redis is used to temporary write the errors raised by several jobs fired for processing millions of rows
      LocalCache.pipelined {
        errors.each {|error| LocalCache.lpush("emp_batch_#{file_upload_id}_errors", error)}
      }

      unless validate_only
        #Process employee policy data
        policies = policies.flatten.uniq
        policies_hash = Policy.where(name: policies).pluck(:name, :id).to_h
        process_rows.each_slice(Employee::BULK_INSERT_SIZE) do |batch|
          email_batch = batch.map{|m| m["Email"]}
          emails_id_hash = Employee.where(email: email_batch).pluck(:email, :id).to_h

          insert_rows = []

          batch.each do |row|
            row["Assigned Policies"].to_s.split("|").map(&:strip).each do |policy|
              insert_rows << EmployeePolicy.new(
                  employee_id: emails_id_hash[row["Email"]],
                  policy_id: policies_hash[policy]
              ) if emails_id_hash[row["Email"]].present?
            end
          end

          #Bulk inser employee policies
          EmployeePolicy.import insert_rows, validate: false

        end
      end

      #Sidekiq Pro provides Batch processing which provides workflow(dependent job execution).
      #Since we are using the free version of sidekiq, created the custom logic of dependent job processing.
      # LOGIC:: Maintain a counter of rows processed in the Redis and update counter in transaction
      # when set of rows for that job gets processed. When the counter reaches to the total rows,
      # process the dependent job(reporting manager linking)
      redis_key = "emp_batch_#{file_upload_id}"
      loop do
        LocalCache.watch(redis_key)
        old_value = LocalCache.get(redis_key).to_i
        new_value = old_value + Employee::BULK_IMPORT_BATCH
        res = LocalCache.multi do |multi|
          multi.set(redis_key, new_value)
        end

        if res.present?
          LocalCache.unwatch
          break
        end
      end

      #When all rows of csv are processed, process the dependent job(reporting manager linking)
      if LocalCache.get(redis_key).to_i >= rows.count
        LocalCache.del("redis_key")
        ProcessEmployeeManager.perform_async(file_upload_id, validate_only)
      end

    end

  end
end
