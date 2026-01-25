class UserSubscription < ApplicationRecord
  # Associations
  belongs_to :user
  belongs_to :subscription_plan

  # Validations
  validates :start_date, presence: true
  validates :status, presence: true, inclusion: { in: %w[active paused cancelled] }

  # Enums
  enum :status, { active: 'active', paused: 'paused', cancelled: 'cancelled' }, validate: true

  # Scopes
  scope :active, -> { where(status: 'active') }
end
