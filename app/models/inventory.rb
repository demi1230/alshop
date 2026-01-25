class Inventory < ApplicationRecord
  # Associations
  belongs_to :sellable_variant

  # Validations
  validates :quantity, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :sellable_variant_id, uniqueness: { scope: :warehouse_id, allow_nil: true }

  # Scopes
  scope :in_stock, -> { where('quantity > ?', 0) }
  scope :out_of_stock, -> { where(quantity: 0) }
end
