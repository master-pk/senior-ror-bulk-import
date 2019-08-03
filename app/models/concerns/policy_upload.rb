module PolicyUpload

  extend ActiveSupport::Concern

  module ClassMethods
    def bulk_create(policies, company_id)

      policies.each_slice(Policy::BULK_INSERT_BATCH) do |batch|
        records = []
        batch.each do |policy_name|
          records << Policy.new(company_id: company_id, name: policy_name)
        end
        Policy.import records, validate: false
      end
    end
  end

end
