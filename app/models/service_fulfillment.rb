class ServiceFulfillment < ApplicationRecord
  # Associations
  belongs_to :order_item
  belongs_to :assigned_user, class_name: 'User', optional: true

  # Validations
  validates :status, presence: true, inclusion: { in: %w[scheduled ongoing completed cancelled] }

  # Enums
  enum :status, { 
    scheduled: 'scheduled', 
    ongoing: 'ongoing', 
    completed: 'completed', 
    cancelled: 'cancelled' 
  }, validate: true

  # Scopes
  scope :pending, -> { where(status: %w[scheduled ongoing]) }
  scope :completed, -> { where(status: 'completed') }

  # Helper methods for metadata
  def completed_at
    return nil unless result.is_a?(Hash)
    Time.parse(result['completed_at']) if result['completed_at']
  end

  def completed_at=(value)
    self.result = (result || {}).merge('completed_at' => value&.iso8601)
  end

  def completion_notes
    result&.dig('completion_notes')
  end

  def completion_notes=(value)
    self.result = (result || {}).merge('completion_notes' => value)
  end
end
