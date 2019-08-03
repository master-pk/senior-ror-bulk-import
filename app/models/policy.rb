class Policy < ApplicationRecord
  include PolicyUpload

  belongs_to :company
  has_and_belongs_to_many :employees

  BULK_INSERT_BATCH = 1000

  validates_uniqueness_of :name, scope: [:company_id]
end
