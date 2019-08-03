class EmployeePolicy < ApplicationRecord
  self.table_name = "employees_policies"

  belongs_to :employee
  belongs_to :policy

end
