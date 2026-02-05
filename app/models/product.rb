class Product < ApplicationRecord
  # Belongs to Sellable (via sellable_id FK)
  belongs_to :sellable

  # Associations
  belongs_to :category, optional: true
  belongs_to :brand, optional: true
  
  # Nested attributes
  accepts_nested_attributes_for :sellable

  # Validations
  validates :sellable, presence: true
  validate :category_must_be_leaf, if: :category_id?
  validate :variant_dimensions_structure

  # Callbacks
  before_save :normalize_variant_dimensions
  after_create :ensure_default_variant

  # Virtual attribute for initial stock
  attr_accessor :initial_stock

  def ensure_default_variant
    # Create default variant if no variants exist
    if sellable.sellable_variants.empty?
      # Generate SKU from sku_base or sellable name
      generated_sku = sku_base.presence || "#{sellable.name.parameterize.upcase[0..9]}-DEFAULT"
      
      variant = sellable.sellable_variants.find_or_create_by!(
        variant_name: 'Default',
        sku: generated_sku
      ) do |v|
        v.is_active = true
      end
      
      # Create inventory for the default variant with initial stock
      unless variant.inventory
        stock_quantity = initial_stock.present? ? initial_stock.to_i : 0
        variant.create_inventory!(quantity: stock_quantity)
      end
    end
  end

  def normalize_variant_dimensions
    # Only initialize to empty hash if it's truly nil, not if it's already set
    self.variant_dimensions ||= {}
    
    # Only transform keys if we have a hash with data
    if variant_dimensions.is_a?(Hash) && variant_dimensions.present?
      self.variant_dimensions = variant_dimensions.transform_keys(&:to_s)
    end
  end

  def variant_dimensions_structure
    return if variant_dimensions.blank?
    
    unless variant_dimensions.is_a?(Hash)
      errors.add(:variant_dimensions, "must be a hash")
      return
    end

    variant_dimensions.each do |name, values|
      unless name.is_a?(String) && name.present?
        errors.add(:variant_dimensions, "dimension names must be non-empty strings")
      end
      
      unless values.is_a?(Array) && values.all? { |v| v.is_a?(String) }
        errors.add(:variant_dimensions, "dimension values must be an array of strings")
      end
    end
  end

  def category_must_be_leaf
    return unless category&.children&.exists?
    errors.add(:category, "must be a leaf category (cannot have sub-categories). " \
                          "Choose a more specific category like '#{category.children.first.name}'.")
  end

  # Scopes
  scope :active, -> { joins(:sellable).where(sellables: { is_active: true }) }
  scope :inactive, -> { joins(:sellable).where(sellables: { is_active: false }) }
  scope :in_category, ->(category_id) { where(category_id: category_id) if category_id.present? }
  
  scope :in_category_tree, ->(parent_category_id) {
    if parent_category_id.present?
      ids = Category.descendant_ids_for(parent_category_id)
      where(category_id: ids) if ids.any?
    end
  }
  
  scope :by_brand, ->(brand_id) { where(brand_id: brand_id) if brand_id.present? }
  scope :search, ->(query) {
    joins(:sellable)
      .where('sellables.name LIKE ?', "%#{sanitize_sql_like(query)}%") if query.present?
  }
  scope :recent, -> { order(created_at: :desc) }

  # Delegations for convenience
  delegate :name, :base_price, :is_active, :sellable_variants, :pricing_rules, to: :sellable
  delegate :name=, :base_price=, :is_active=, to: :sellable

  # Business logic
  def current_price(user: nil, quantity: 1)
    PricingCalculator.calculate(
      sellable: sellable,
      user: user,
      quantity: quantity
    )
  end

  def available_variants
    sellable_variants.where(is_active: true)
  end

  def in_stock?
    is_active? && sellable.present?
  end

  def has_variants?
    sellable_variants.any?
  end

  def display_name
    brand.present? ? "#{brand.name} #{name}" : name
  end

  # Build a new Product with associated Sellable
  def self.build_with_sellable(attributes = {})
    product = new
    product.build_sellable(
      sellable_type: 'Product',
      name: attributes[:name],
      base_price: attributes[:base_price] || 0,
      is_active: attributes[:is_active] || true
    )
    product.category_id = attributes[:category_id]
    product.brand_id = attributes[:brand_id]
    product
  end

  # Variant dimension helpers
  def dimension_names
    (variant_dimensions || {}).keys
  end

  def dimension_values(dimension_name)
    (variant_dimensions || {})[dimension_name.to_s] || []
  end

  def add_dimension(name, values = [])
    self.variant_dimensions ||= {}
    self.variant_dimensions[name.to_s] = Array(values).map(&:to_s)
  end

  def remove_dimension(name)
    self.variant_dimensions ||= {}
    self.variant_dimensions.delete(name.to_s)
  end

  def generate_variant_combinations
    return [] if variant_dimensions.blank?
    
    dimensions = variant_dimensions.values
    return [] if dimensions.any?(&:empty?)
    
    # Generate Cartesian product
    combinations = dimensions.first.product(*dimensions[1..-1])
    
    # Convert to hash format
    dimension_keys = variant_dimensions.keys
    combinations.map do |combo_values|
      dimension_keys.zip(Array(combo_values).flatten).to_h
    end
  end
end
