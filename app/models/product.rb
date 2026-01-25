class Product < ApplicationRecord
  # Belongs to Sellable (via sellable_id FK)
  belongs_to :sellable

  # Associations
  belongs_to :category, optional: true
  belongs_to :brand, optional: true

  # Validations
  validates :sellable, presence: true
  validate :category_must_be_leaf, if: :category_id?

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
end
