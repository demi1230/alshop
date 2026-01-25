class CartItem < ApplicationRecord
  # Associations
  belongs_to :cart
  belongs_to :sellable
  belongs_to :sellable_variant, optional: true

  # Validations
  validates :quantity, presence: true, numericality: { only_integer: true, greater_than: 0 }
end
