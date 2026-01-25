class SellableVariant < ApplicationRecord
  # The 'attributes' column name conflicts with AR methods.
  # We'll silence all related dangerous attribute warnings.
  class << self
    def dangerous_attribute_method?(name)
      # Allow 'attributes' and all its derived methods
      return false if name.to_s.start_with?('attributes')
      super
    end
  end
  
  # Associations
  belongs_to :sellable
  has_one :inventory, dependent: :destroy
  has_many :pricing_rules, dependent: :destroy
  has_many :cart_items, dependent: :restrict_with_error
  has_many :order_items, dependent: :restrict_with_error

  # Validations
  validates :variant_name, presence: true
  validates :sku, uniqueness: { allow_nil: true }
  validates :price_override, numericality: { greater_than_or_equal_to: 0, allow_nil: true }
  validates :is_active, inclusion: { in: [true, false] }

  # Scopes
  scope :active, -> { where(is_active: true) }

  # Methods
  def effective_price
    price_override || sellable.base_price
  end

  def discounted_price
    PricingCalculator.calculate(sellable: sellable, variant: self)
  end

  def has_discount?
    effective_price != discounted_price
  end

  def discount_percentage
    return 0 unless has_discount?
    ((effective_price - discounted_price) / effective_price * 100).round
  end
end
