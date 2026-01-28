class Order < ApplicationRecord
  include Orderable

  # Associations
  belongs_to :user, optional: true
  has_many :order_items, dependent: :destroy
  has_many :service_fulfillments, through: :order_items
  has_one :shipping_address, dependent: :destroy

  accepts_nested_attributes_for :shipping_address

  # Validations
  validates :status, presence: true, inclusion: { in: %w[pending paid shipped delivered cancelled] }
  validates :total_price, presence: true, numericality: { greater_than_or_equal_to: 0 }

  # Enums
  enum :status, {
    pending: 'pending',
    paid: 'paid',
    shipped: 'shipped',
    delivered: 'delivered',
    cancelled: 'cancelled'
  }, validate: true

  # Scopes - Replace query objects
  scope :recent, -> { order(created_at: :desc) }
  scope :for_user, ->(user) { where(user: user) }
  scope :by_status, ->(status) { where(status: status) if status.present? }
  scope :in_date_range, ->(from, to) { where(created_at: from..to) if from.present? && to.present? }
  
  # Status-based scopes for dashboard/reporting
  scope :completed, -> { where(status: ['paid', 'shipped', 'delivered']) }
  scope :active, -> { where(status: ['pending', 'paid', 'shipped']) }

  # Business Logic - State Transitions (replaces Orders::MarkPaid service)
  def mark_as_paid!(payment_method:, transaction_id:)
    raise OrderStateError, "Order cannot be marked as paid in #{status} state" unless can_be_paid?

    transaction do
      update!(
        status: :paid,
        metadata: (metadata || {}).merge(
          payment_method: payment_method,
          transaction_id: transaction_id,
          paid_at: Time.current.iso8601
        )
      )

      create_fulfillments_if_needed
    end
  end

  # Replaces Orders::Cancel service
  def cancel!(reason: nil)
    raise OrderStateError, "Order cannot be cancelled in #{status} state" unless can_be_cancelled?

    transaction do
      update!(
        status: :cancelled,
        metadata: (metadata || {}).merge(
          cancellation_reason: reason,
          cancelled_at: Time.current.iso8601
        )
      )

      # Cancel any pending fulfillments
      service_fulfillments.where(status: 'scheduled').update_all(status: 'cancelled')
    end
  end

  # Replaces Orders::Refund service
  def refund!(amount:, reason:)
    raise OrderStateError, "Order cannot be refunded in #{status} state" unless paid? || shipped? || delivered?
    raise ArgumentError, "Refund amount cannot exceed net amount" if amount > net_amount

    transaction do
      refunds = (metadata || {})['refunds'] || []
      refunds << {
        amount: amount,
        reason: reason,
        refunded_at: Time.current.iso8601
      }

      update!(metadata: metadata.merge('refunds' => refunds))
    end
  end

  # State management
  def mark_as_shipped!
    raise OrderStateError, "Order cannot be shipped in #{status} state" unless can_be_shipped?

    update!(status: :shipped)
  end

  def mark_as_delivered!
    raise OrderStateError, "Order cannot be delivered in #{status} state" unless shipped?

    update!(status: :delivered)
  end

  # Calculations (replaces Orders::DetailSummary)
  def total_refunded
    refunds = (metadata || {})['refunds'] || []
    refunds.sum { |r| r['amount'].to_f }
  end

  def net_amount
    total_price - total_refunded
  end

  def payment_method
    metadata&.dig('payment_method')
  end

  def transaction_id
    metadata&.dig('transaction_id')
  end

  def paid_at
    Time.parse(metadata&.dig('paid_at')) if metadata&.dig('paid_at')
  end

  def shipped_at
    Time.parse(metadata&.dig('shipped_at')) if metadata&.dig('shipped_at')
  end

  def cancelled_at
    Time.parse(metadata&.dig('cancelled_at')) if metadata&.dig('cancelled_at')
  end

  def cancellation_reason
    metadata&.dig('cancellation_reason')
  end

  def order_number
    metadata&.dig('order_number') || "ORD-#{id}"
  end

  def admin_notes
    metadata&.dig('admin_notes')
  end

  def admin_notes=(value)
    self.metadata = (metadata || {}).merge('admin_notes' => value)
  end

  def tracking_number
    metadata&.dig('tracking_number')
  end

  def tracking_number=(value)
    self.metadata = (metadata || {}).merge('tracking_number' => value)
  end

  private

  # Simplified fulfillment creation (replaces FulfillmentOrchestrationService)
  def create_fulfillments_if_needed
    order_items.includes(sellable: :sellable_type_record).find_each do |item|
      next unless item.sellable.sellable_type == 'Service'

      ServiceFulfillment.create!(
        order_item: item,
        status: :scheduled,
        scheduled_at: 3.days.from_now,
        metadata: {}
      )
    end
  end

  class OrderStateError < StandardError; end
end
