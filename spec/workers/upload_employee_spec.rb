require 'rails_helper'
require 'sidekiq/testing'
Sidekiq::Testing.inline!

RSpec.describe ::Workers::UploadEmployee, :file_upload_test => true  do

  let(:company) {FactoryBot.create(:company)}

  describe "file with errors" do

    it "should test company file validation" do

      file_upload = FactoryBot.create(:file_upload, attachable_id: company.id, data_file: Files.invalid_csv)
      ::Workers::UploadEmployee.new.perform(file_upload.id, true)

      expect(file_upload.status).to eq("in_progress")
      file_upload.reload
      expect(file_upload.status).to eq("failed")

    end

    it "should test file error data" do
      file_upload = FactoryBot.create(:file_upload, attachable_id: company.id, data_file: Files.invalid_csv)

      ::Workers::UploadEmployee.new.perform(file_upload.id, true)

      file_upload.reload
      errors = 'Row 2 Error: ["Email is invalid"]'+ "\n" +
          'Rows with \'Report To\' emails don@example.com doesn\'t exist in sheet' + "\n"
      expect(file_upload.error_log_file.download).to eq(errors)
    end

  end

  describe "file without errors" do

    it "should process successfully" do
      file_upload = FactoryBot.create(:file_upload, attachable_id: company.id, data_file: Files.csv)

      ::Workers::UploadEmployee.new.perform(file_upload.id, true)

      file_upload.reload
      expect(file_upload.status).to eq("completed")
      expect(file_upload.error_log_file.attached?).to be_falsey
    end

    it "should create valid data" do

      file_upload = FactoryBot.create(:file_upload, attachable_id: company.id, data_file: Files.csv)

      ::Workers::UploadEmployee.new.perform(file_upload.id, true)

      file_upload.reload

      expect(Employee.count).to eq(3)

      #Test each employee data
      bob = Employee.find_by_email("bob@example.com")
      jon = Employee.find_by_email("jon@example.com")
      arya = Employee.find_by_email("arya@example.com")

      expect(bob.name).to eq("Bob")
      expect(jon.name).to eq("Jon")
      expect(arya.name).to eq("Arya")

      expect(bob.phone).to eq("081231231")
      expect(jon.phone).to eq("0123123")
      expect(arya.phone).to eq("0123123")

      expect(bob.parent_id).to eq(jon.id)
      expect(jon.parent_id).to eq(nil)
      expect(arya.parent_id).to eq(bob.id)

      expect(bob.policies.pluck(:name)).to eq(["Sick Leave", "Annual Leave"])
      expect(jon.policies.pluck(:name)).to eq(["Sick Leave", "Annual Leave"])
      expect(arya.policies.pluck(:name)).to eq(["Sick Leave", "Annual Leave", "Maternity Leave"])

    end

  end


end