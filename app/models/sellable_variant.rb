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
  
  # Nested attributes
  accepts_nested_attributes_for :inventory

  # Validations
  validates :variant_name, presence: true
  validates :sku, uniqueness: { allow_blank: true }
  validates :price_override, numericality: { greater_than_or_equal_to: 0, allow_nil: true }
  validates :is_active, inclusion: { in: [true, false] }

  # Callbacks
  before_validation :generate_sku_if_blank, on: :create
  after_create :ensure_inventory

  # Scopes
  scope :active, -> { where(is_active: true) }

  # Methods
  def generate_sku_if_blank
    return if sku.present?
    
    # Generate SKU from sellable name and variant name
    base = sellable.name.upcase.gsub(/[^A-Z0-9]/, '-').squeeze('-').chomp('-')
    variant_part = variant_name.upcase.gsub(/[^A-Z0-9]/, '-').squeeze('-').chomp('-')
    
    # Try with base + variant first
    proposed_sku = "#{base}-#{variant_part}"
    
    # If that exists, add a random suffix
    counter = 1
    while SellableVariant.exists?(sku: proposed_sku)
      proposed_sku = "#{base}-#{variant_part}-#{counter}"
      counter += 1
    end
    
    self.sku = proposed_sku
  end
  
  def ensure_inventory
    create_inventory!(quantity: 0) unless inventory
  end

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
