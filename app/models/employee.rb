class Employee < ApplicationRecord
  belongs_to :company
  has_and_belongs_to_many :policies

  validates :name, presence: true
  validates :email, presence:true, format: { with: URI::MailTo::EMAIL_REGEXP }  #Moved email unique validation to DB

  BULK_IMPORT_BATCH = 100000
  BULK_INSERT_SIZE = 1000

  acts_as_nested_set
end
