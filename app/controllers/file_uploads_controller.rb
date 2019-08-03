class FileUploadsController < ApplicationController

  def index
    @file_uploads = FileUpload.includes(data_file_attachment: :blob, error_log_file_attachment: :blob).all
  end

  def new
    @companies = Company.all
    @file_upload = FileUpload.new
  end

  def create
    @companies = Company.all
    @file_upload = FileUpload.new(file_upload_params)
    @file_upload.status = FileUpload.statuses["in_progress"]
    @file_upload.attachable_type = "Company"
    respond_to do |format|
      if @file_upload.save
        #calling csv data upload method in background
        ::Workers::UploadEmployee.perform_async(@file_upload.id, true)

        format.html { redirect_to file_uploads_path, notice: 'Company das has successfully uploaded. File processing is under progress.' }
      else
        format.html { render :new }
      end
    end
  end

  private

  def file_upload_params
    params.require(:file_upload).permit(:status, :attachable_id, :data_file)
  end

end