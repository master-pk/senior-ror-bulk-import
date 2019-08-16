require 'rails_helper'

RSpec.describe FileUploadsController, :type => :controller, :file_upload_test => true do

  describe "GET index" do
    it "assigns all uploads as @file_uploads" do
      file_upload = FactoryBot.create(:file_upload, attachable_id: FactoryBot.create(:company).id)
      get :index
      expect(assigns(:file_uploads)).to eq([file_upload])
    end
  end

  describe "GET new" do
    it "assigns a new upload as @file_upload" do
      get :new
      expect(assigns(:file_upload)).to be_a_new(FileUpload)
    end
  end

  describe "POST create" do

  end

  describe "POST create" do
    describe "with invalid params" do
      it "assigns a newly created but unsaved upload as @file_upload" do
        post :create, params: {
            file_upload: {
               attachable_id: 1,    #Company id is not valid
               data_file: Files.csv
            }
        }
        expect(assigns(:file_upload)).to be_a_new(FileUpload)
      end

      it "re-renders the 'new' template" do
        post :create, params: {
            file_upload: {
                attachable_id: 1,
                data_file: Files.csv
            }
        }
        expect(response).to render_template("new")
      end
    end

    describe "with valid params" do
      it "creates a new FileUpload" do
        post :create, params: {
            file_upload: {
                attachable_id: FactoryBot.create(:company).id,
                data_file: Files.csv
            }
        }
        expect(assigns(:file_upload)).to be_a(FileUpload)
        expect(FileUpload.count).to eq(1)
      end

      it "redirects to index page" do
        post :create, params: {
            file_upload: {
                attachable_id: FactoryBot.create(:company).id,
                data_file: Files.csv
            }
        }
        expect(response).to redirect_to(file_uploads_path)
      end
    end

  end

end
