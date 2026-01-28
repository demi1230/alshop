# frozen_string_literal: true

# PricingCalculator - Calculates final price for a sellable/variant
# based on pricing rules using first-match resolution.
#
# Simplified for internship project - focuses on core pricing logic.
#
# Usage:
#   price = PricingCalculator.calculate(
#     sellable: product.sellable,
#     variant: variant,
#     user: current_user,
#     quantity: 2
#   )
#
class PricingCalculator
  def self.calculate(sellable:, variant: nil, user: nil, quantity: 1)
    new(sellable: sellable, variant: variant, user: user, quantity: quantity).calculate
  end

  def initialize(sellable:, variant: nil, user: nil, quantity: 1)
    @sellable = sellable
    @variant = variant
    @user = user
    @quantity = quantity
  end

  def calculate
    base = calculate_base_price
    rule = find_applicable_rule

    return base unless rule

    apply_discount(base, rule)
  end

  private

  attr_reader :sellable, :variant, :user, :quantity

  def calculate_base_price
    return variant.effective_price if variant
    sellable.base_price
  end

  def find_applicable_rule
    # Find the first active rule that matches
    # Priority: variant-specific rule > sellable rule
    rules = PricingRule
      .where('valid_from IS NULL OR valid_from <= ?', Time.current)
      .where('valid_to IS NULL OR valid_to >= ?', Time.current)
      .order(priority: :desc)

    # If variant is specified, first look for variant-specific rules
    if variant
      variant_rule = rules.where(sellable_variant: variant).first
      return variant_rule if variant_rule
    end

    # Fall back to sellable-level rules (where sellable_variant_id is NULL)
    rules.where(sellable: sellable, sellable_variant_id: nil).first
  end

  def apply_discount(base, rule)
    case rule.discount_type
    when 'percentage'
      discount_multiplier = 1 - (rule.value / 100.0)
      (base * discount_multiplier).round(2)
    when 'fixed'
      new_price = base - rule.value
      [new_price, 0].max.round(2)
    when 'override'
      rule.value
    else
      base
    end
  end
end
