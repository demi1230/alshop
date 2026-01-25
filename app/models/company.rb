class Company < ApplicationRecord
  # Associations
  belongs_to :parent_company, class_name: 'Company', optional: true
  has_many :sub_companies, class_name: 'Company', foreign_key: 'parent_company_id', dependent: :nullify
  has_many :users, dependent: :nullify
  has_many :pricing_rules, dependent: :destroy
  has_many :subscription_plans, dependent: :destroy

  # Validations
  validates :name, presence: true
  validates :is_active, inclusion: { in: [true, false] }
end
