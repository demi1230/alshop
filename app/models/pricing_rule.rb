class PricingRule < ApplicationRecord
  # Associations
  belongs_to :sellable, optional: true
  belongs_to :sellable_variant, optional: true
  belongs_to :company, optional: true
  belongs_to :sub_company, class_name: 'Company', optional: true

  # Validations
  validates :channel, presence: true
  validates :discount_type, presence: true
  validates :value, presence: true, numericality: true
  validates :priority, presence: true, numericality: { only_integer: true }
  validate :company_required_for_company_channel
  validate :promo_code_required_for_promo_channel
  validate :valid_date_range

  # Enums (without validate: true since we're using string values directly)
  enum :channel, { 
    public_channel: 'public', 
    company: 'company', 
    sub_company: 'sub_company', 
    partner: 'partner', 
    promo: 'promo' 
  }, prefix: :channel

  enum :discount_type, { 
    percentage: 'percentage', 
    fixed: 'fixed', 
    override: 'override' 
  }

  # Scopes
  scope :active, -> { where('valid_from IS NULL OR valid_from <= ?', Time.current).where('valid_to IS NULL OR valid_to >= ?', Time.current) }
  scope :by_priority, -> { order(priority: :desc) }

  private

  def company_required_for_company_channel
    if %w[company sub_company].include?(channel) && company_id.blank?
      errors.add(:company_id, "must be present for #{channel} channel")
    end
  end

  def promo_code_required_for_promo_channel
    if channel == 'promo' && promo_code.blank?
      errors.add(:promo_code, 'must be present for promo channel')
    end
  end

  def valid_date_range
    if valid_from.present? && valid_to.present? && valid_from >= valid_to
      errors.add(:valid_to, 'must be after valid_from')
    end
  end
end
