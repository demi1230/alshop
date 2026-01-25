# frozen_string_literal: true

# Orderable concern - State machine logic for Order model
# Extracted to keep Order model focused on business logic
module Orderable
  extend ActiveSupport::Concern

  included do
    # Callbacks for state transitions
    after_update :log_status_change, if: :saved_change_to_status?
  end

  # State guards
  def can_be_paid?
    pending?
  end

  def can_be_shipped?
    paid?
  end

  def can_be_delivered?
    shipped?
  end

  def can_be_cancelled?
    pending? || paid?
  end

  def can_be_refunded?
    paid? || shipped? || delivered?
  end

  private

  def log_status_change
    Rails.logger.info "Order ##{id} status changed from #{status_before_last_save} to #{status}"
  end
end
