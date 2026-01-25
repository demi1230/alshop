class Sellable < ApplicationRecord
  # Polymorphic-like association (manual implementation)
  # Product/Service have sellable_id FK pointing here
  has_one :product, dependent: :destroy
  has_one :service, dependent: :destroy

  # Associations
  has_many :sellable_variants, dependent: :destroy
  has_many :pricing_rules, dependent: :destroy
  has_many :subscription_plans, dependent: :destroy
  has_many :specifications, dependent: :destroy
  has_many :category_attributes, through: :specifications
  has_many :cart_items, dependent: :restrict_with_error
  has_many :order_items, dependent: :restrict_with_error

  # Validations
  validates :name, presence: true
  validates :sellable_type, presence: true, inclusion: { in: %w[Product Service] }
  validates :base_price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :is_active, inclusion: { in: [true, false] }

  # Scopes
  scope :active, -> { where(is_active: true) }
  scope :products, -> { where(sellable_type: 'Product') }
  scope :services, -> { where(sellable_type: 'Service') }
  
  # Helper to get the specific type
  def sellable_entity
    case sellable_type
    when 'Product'
      product
    when 'Service'
      service
    end
  end
end
