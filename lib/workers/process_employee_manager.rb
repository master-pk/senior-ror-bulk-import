module Workers
  class ProcessEmployeeManager
    include Sidekiq::Worker
    sidekiq_options queue: 'employee_upload', retry: true, backtrace: true

    #TODO: Clean validation and creation flow
    def perform(*args)

      file_upload_id = args[0]
      validate_only = args[1]

      file_upload = FileUpload.find_by_id(file_upload_id)

      if file_upload.blank?
        Rails.logger.error("[Workers::ProcessEmployeeManager] Invalid file upload id - #{file_upload_id}")
        return
      end

      if validate_only
        errors = LocalCache.lrange("emp_batch_#{file_upload_id}_errors", 0, -1)
        #Validate "Report To"

        process_rows = CSV.parse(file_upload.data_file.download, headers: true)
        emp_emails = process_rows["Email"]
        manager_emails = process_rows["Report To"].reject {|email| email.blank?}

        diff = manager_emails - emp_emails
        non_existent_manager_emails = diff - Employee.where(email: diff).pluck(:email)

        if non_existent_manager_emails.present?
          errors << "Rows with 'Report To' emails #{non_existent_manager_emails.join(", ")} doesn't exist in sheet"
        end

        if errors.present?
          file_upload.status = FileUpload.statuses["failed"]
          temp_log_file =  Tempfile.new([ 'error_log_file', '.txt' ])
          errors.each do |error|
            temp_log_file.write("#{error}\n")
          end
          temp_log_file.rewind
          file_upload.error_log_file.attach(
            io: File.open(temp_log_file.path), filename: 'error_log_file.txt',
            content_type: 'application/text'
          )
          file_upload.save!
        else
          Workers::UploadEmployee.perform_async(file_upload_id, false)
        end

      else
        link_managers(file_upload)
      end

    end

    def link_managers(file_upload)
      process_rows = CSV.parse(file_upload.data_file.download, headers: true)[0..-1]

      emails_id_hash = {}
      managers = {}

      process_rows.each_slice(Employee::BULK_INSERT_SIZE) do |batch|
        email_batch = batch.map{|m| m["Email"]}
        #Make select queries in batch
        emails_id_hash.merge!(Employee.where(email: email_batch).pluck(:email, :id).to_h)
      end

      process_rows.each_with_index do |row, index|
        next if row["Report To"].blank?

        manager_emp_id = emails_id_hash[row["Report To"]]
        emp_id = emails_id_hash[row["Email"]]
        if manager_emp_id.present? && emp_id.present?
          managers[manager_emp_id] = [] if managers[manager_emp_id].blank?
          managers[manager_emp_id] << emp_id
        end
      end

      #Link managers
      managers.each do |manager_emp_id, emp_ids|
        Employee.where(id: emp_ids).update_all(parent_id: manager_emp_id)
      end

      file_upload.status = FileUpload.statuses["completed"]
      file_upload.save!
    end

  end
end
