class ServiceConfigSpec < ApplicationRecord
  # Associations
  belongs_to :service

  # Validations
  validates :field_name, presence: true
  validates :data_type, presence: true, inclusion: { in: %w[int bool string] }
  validates :unit_price, presence: true, numericality: { greater_than_or_equal_to: 0 }

  # Enums
  enum :data_type, { int: 'int', bool: 'bool', string: 'string' }, validate: true

  # Methods
  def has_options?
    options.present? && options.is_a?(Array) && options.any?
  end
end
