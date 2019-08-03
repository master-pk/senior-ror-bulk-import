class FileUpload < ApplicationRecord

  belongs_to :attachable, polymorphic: true

  has_one_attached :data_file
  has_one_attached :error_log_file

  validate :mime_type
  validate :already_in_progress

  enum status: {
    in_progress: "In Progress",
    completed: "Completed",
    failed: "Failed"
  }

  private

  def mime_type
    if data_file.attached? && !data_file.content_type.in?(%w(text/plain text/csv))
      data_file.purge # delete the uploaded file
      errors.add(:data_file, 'Must be a CSV')
    end
  end

  def already_in_progress
    if !self.persisted? && FileUpload.where(attachable_id: attachable_id, status: FileUpload.statuses[:in_progress]).exists?
      errors.add(:attachable, "File upload already in progress. Retry when previous upload finished for the entity e.g Company. Try uploading file for other company")
    end
  end

end
