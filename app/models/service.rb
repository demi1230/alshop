class Service < ApplicationRecord
  # Belongs to Sellable (via sellable_id FK)
  belongs_to :sellable

  # Associations
  belongs_to :category, optional: true
  has_many :service_config_specs, dependent: :destroy

  # Delegations
  delegate :name, :base_price, :is_active, :sellable_variants, :pricing_rules, to: :sellable

  # Validations
  validates :service_type, presence: true, inclusion: { in: %w[hourly fixed subscription] }
  validates :requires_schedule, inclusion: { in: [true, false] }
  validate :category_must_be_leaf, if: :category_id?

  def category_must_be_leaf
    return unless category&.children&.exists?
    errors.add(:category, "must be a leaf category (cannot have sub-categories). " \
                          "Choose a more specific category like '#{category.children.first.name}'.")
  end

  # Enums
  enum :service_type, { hourly: 'hourly', fixed: 'fixed', subscription: 'subscription' }, validate: true
end
