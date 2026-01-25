class Specification < ApplicationRecord
  # Associations
  belongs_to :sellable
  belongs_to :category_attribute

  # Validations
  validates :value, presence: true
  validates :category_attribute_id, uniqueness: { scope: :sellable_id }
end
