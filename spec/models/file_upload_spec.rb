require 'rails_helper'

RSpec.describe FileUpload, :type => :model, :file_upload_test => true do

  it "has a valid factory" do
    expect(FactoryBot.build(:file_upload, attachable_id: FactoryBot.create(:company).id)).to be_valid
  end

  describe "Validations" do

    it "is invalid with non csv file" do
      invalid_upload = FactoryBot.build(:invalid_file_upload, attachable_id: FactoryBot.create(:company).id)

      expect(invalid_upload.save).to be_falsey
      expect(invalid_upload.errors.messages[:data_file]).to eq(["Must be a CSV"])
    end

    it "is invalid when a upload already in progress" do
      attachable_id = FactoryBot.create(:company).id

      valid = FactoryBot.build(:file_upload, attachable_id: attachable_id)
      valid.save

      invalid_upload = FactoryBot.build(:file_upload, attachable_id: attachable_id)
      expect(invalid_upload.save).to be_falsey
      expect(invalid_upload.errors.messages[:attachable]).to eq(["File upload already in progress. " +
          "Retry when previous upload finished for the entity e.g Company. " +
          "Try uploading file for other company"
      ])
    end

  end

end
