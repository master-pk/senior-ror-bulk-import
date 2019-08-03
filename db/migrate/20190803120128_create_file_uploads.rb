class CreateFileUploads < ActiveRecord::Migration[5.2]
  def change
    create_table :file_uploads do |t|
      t.string :status
      t.references :attachable, polymorphic: true

      t.timestamps
    end
  end
end
