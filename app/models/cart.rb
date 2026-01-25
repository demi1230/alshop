class Cart < ApplicationRecord
  # Associations
  belongs_to :user, optional: true
  has_many :cart_items, dependent: :destroy

  # Validations
  validates :status, presence: true, inclusion: { in: %w[active converted abandoned] }
  validate :unique_active_cart_per_user

  # Enums
  enum :status, { active: 'active', converted: 'converted', abandoned: 'abandoned' }, validate: true

  # Scopes
  scope :active, -> { where(status: 'active') }
  scope :expired, -> { where('expires_at < ?', Time.current) }
  scope :for_user, ->(user) { where(user: user) }

  # Business logic - Cart operations
  def add_item(sellable:, quantity: 1, variant: nil)
    raise ArgumentError, "Quantity must be positive" if quantity <= 0

    existing = cart_items.find_by(
      sellable: sellable,
      sellable_variant: variant
    )

    if existing
      existing.increment!(:quantity, quantity)
      existing
    else
      cart_items.create!(
        sellable: sellable,
        sellable_variant: variant,
        quantity: quantity,
        price_at_add: sellable.base_price
      )
    end
  end

  def update_item_quantity(cart_item_id, quantity)
    item = cart_items.find(cart_item_id)

    if quantity <= 0
      item.destroy
    else
      item.update!(quantity: quantity)
    end
  end

  def remove_item(cart_item_id)
    cart_items.find(cart_item_id).destroy
  end

  def total_price
    cart_items.sum { |item| item.quantity * item.price_at_add }
  end

  def item_count
    cart_items.sum(:quantity)
  end

  def empty?
    cart_items.empty?
  end

  def clear!
    cart_items.destroy_all
  end

  def convert_to_order!
    raise CartStateError, "Cart is already converted" unless active?

    update!(status: :converted)
  end

  def mark_as_abandoned!
    update!(status: :abandoned)
  end

  private

  def unique_active_cart_per_user
    if active? && user_id.present?
      existing = Cart.where(user_id: user_id, status: 'active').where.not(id: id)
      if existing.exists?
        errors.add(:base, 'User can only have one active cart')
      end
    end
  end

  class CartStateError < StandardError; end
end
