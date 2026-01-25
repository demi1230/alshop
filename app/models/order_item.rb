class OrderItem < ApplicationRecord
  # Associations
  belongs_to :order
  belongs_to :sellable
  belongs_to :sellable_variant, optional: true
  has_one :service_fulfillment, dependent: :destroy

  # Validations
  validates :quantity, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :price_at_purchase, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :line_total, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validate :line_total_matches_calculation

  private

  def line_total_matches_calculation
    expected_total = (price_at_purchase * quantity).round(2)
    if line_total.present? && line_total.round(2) != expected_total
      errors.add(:line_total, "must equal price_at_purchase * quantity (expected #{expected_total})")
    end
  end
end
