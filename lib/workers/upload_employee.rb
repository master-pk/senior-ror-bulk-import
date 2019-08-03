module Workers
  class UploadEmployee
    include Sidekiq::Worker
    sidekiq_options queue: 'employee_upload', retry: true, backtrace: true

    def perform(*args)

      file_upload_id = args[0]
      validate_only = args[1]   #Job will act for validation only(no modification in data)
      file_upload = FileUpload.find_by_id(file_upload_id)

      if file_upload.blank?
        Rails.logger.error("[Workers::UploadEmployee] Invalid file upload id - #{file_upload_id}")
        return
      end

      rows = CSV.parse(file_upload.data_file.download, headers: true)

      unless validate_only
        #Find policies which do not exist with company
        policies = rows["Assigned Policies"].map{|m| m.to_s.split("|").map(&:strip)}.flatten.uniq
        company_id = file_upload.attachable_id
        exisitng_policies = Policy.where(company_id: company_id).pluck(:name)
        new_policies = policies - exisitng_policies

        #Create company policies in bulk.
        #Policy creation in here will ensure the subsequent jobs have not to create the policy
        Policy.bulk_create(new_policies, company_id)
      end

      total_rows = rows.count
      current_row = 0

      #First individually process the the rows i.e create the Employee entries.
      #On successful creation of all the employees, populate their Reporting Managers

      #Sidekiq Pro provides Batch processing which provides workflow.
      #Since we are using the free version of sidekiq, created the custom logic of dependent job processing.
      # LOGIC:: Maintain a counter of rows processed in the Redis and update counter in transaction
      # when set of rows for that job gets processed. When the counter reaches to the total rows,
      # process the dependent job(reporting manager linking)
      LocalCache.set("emp_batch_#{file_upload_id}", 0)
      begin
        #Process 100000 rows of CSV in a job
        Workers::ProcessEmployeeRows.perform_async(
            file_upload_id, current_row, [current_row + Employee::BULK_IMPORT_BATCH, total_rows].min,
            validate_only
        )
        current_row = current_row + Employee::BULK_IMPORT_BATCH

      end while current_row < total_rows
    end

  end
end
