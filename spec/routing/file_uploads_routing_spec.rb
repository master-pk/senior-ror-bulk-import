require "rails_helper"

RSpec.describe FileUploadsController, :type => :routing, :file_upload_test => true do
  describe "routing" do

    it "routes to #index" do
      expect(:get => "/file_uploads").to route_to("file_uploads#index")
    end

    it "routes to #new" do
      expect(:get => "/file_uploads/new").to route_to("file_uploads#new")
    end

    it "routes to #create" do
      expect(:post => "/file_uploads").to route_to("file_uploads#create")
    end

  end
end
