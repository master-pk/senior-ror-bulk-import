FactoryBot.define do
  factory :file_upload, class: FileUpload do
    attachable_type {"Company"}
    attachable_id {1}
    status {"In Progress"}
    data_file { Files.csv }
  end

  factory :invalid_file_upload, class: FileUpload do
    attachable_type {"Company"}
    attachable_id {1}
    status {"In Progress"}
    data_file { Files.png }
  end
end
