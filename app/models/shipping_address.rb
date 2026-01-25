class ShippingAddress < ApplicationRecord
  # Associations
  belongs_to :order

  # Validations
  validates :city, presence: true
  validates :phone_number, presence: true
end
