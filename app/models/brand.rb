class Brand < ApplicationRecord
  # Associations
  has_many :products, dependent: :restrict_with_error

  # Validations
  validates :name, presence: true
end
