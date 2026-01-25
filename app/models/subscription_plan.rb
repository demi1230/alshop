class SubscriptionPlan < ApplicationRecord
  # Associations
  belongs_to :sellable
  belongs_to :company, optional: true
  has_many :user_subscriptions, dependent: :restrict_with_error

  # Validations
  validates :billing_cycle, presence: true, inclusion: { in: %w[monthly yearly] }
  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :trial_days, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  # Enums
  enum :billing_cycle, { monthly: 'monthly', yearly: 'yearly' }, validate: true
end
