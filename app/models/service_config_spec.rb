class ServiceConfigSpec < ApplicationRecord
  # Associations
  belongs_to :service

  # Validations
  validates :field_name, presence: true
  validates :data_type, presence: true, inclusion: { in: %w[string integer date boolean option] }
  validates :unit_price, presence: true, numericality: { greater_than_or_equal_to: 0 }

  # Methods
  def has_options?
    data_type == 'option' && parsed_options.present? && parsed_options.any?
  end

  def parsed_options
    return [] if options.blank?
    
    if options.is_a?(String)
      begin
        JSON.parse(options)
      rescue JSON::ParserError
        []
      end
    elsif options.is_a?(Array)
      options
    else
      []
    end
  end
end
