require "test_helper"

class PricingEngineTest < ActiveSupport::TestCase
  setup do
    # Create Sellable and Product (Product belongs_to Sellable)
    @sellable = Sellable.create!(
      name: "Test Product",
      sellable_type: "Product",
      base_price: 100.00,
      is_active: true
    )
    
    @product = Product.create!(
      sellable: @sellable,
      sku_base: "TEST"
    )

    @variant = SellableVariant.create!(
      sellable: @sellable,
      variant_name: "Standard",
      sku: "TEST-001",
      price_override: 150.00
    )

    @company = Company.create!(name: "Test Corp", is_active: true)
    @sub_company = Company.create!(
      name: "Test Corp Sub",
      parent_company: @company,
      is_active: true
    )

    @user = User.create!(
      email: "user@test.com",
      password: "password123",
      company: @company,
      role: "customer"
    )

    @user_sub = User.create!(
      email: "subuser@test.com",
      password: "password123",
      company: @sub_company,
      role: "customer"
    )
  end

  # === Base Price Tests ===

  test "returns base price when no rules apply" do
    result = PricingEngine.call(sellable: @sellable)

    assert_equal 100.00, result.price
    assert_equal 100.00, result.base_price
    assert_nil result.applied_rule
    assert_not result.rule_applied?
  end

  test "uses variant price_override as base price" do
    result = PricingEngine.call(sellable: @sellable, variant: @variant)

    assert_equal 150.00, result.price
    assert_equal 150.00, result.base_price
  end

  # === Public Channel Tests ===

  test "applies public channel rule" do
    rule = PricingRule.create!(
      sellable: @sellable,
      channel: "public",
      discount_type: "percentage",
      value: 10,
      priority: 1
    )

    result = PricingEngine.call(sellable: @sellable)

    assert_equal 90.00, result.price
    assert_equal rule, result.applied_rule
    assert_equal 10.00, result.discount_amount
  end

  # === Company Channel Tests ===

  test "applies company-specific rule when user has company" do
    rule = PricingRule.create!(
      sellable: @sellable,
      channel: "company",
      company: @company,
      discount_type: "fixed",
      value: 20,
      priority: 10
    )

    result = PricingEngine.call(sellable: @sellable, user: @user)

    assert_equal 80.00, result.price
    assert_equal rule, result.applied_rule
  end

  test "does not apply company rule when user has no company" do
    user_no_company = User.create!(
      email: "nocompany@test.com",
      password: "password123",
      role: "customer"
    )

    PricingRule.create!(
      sellable: @sellable,
      channel: "company",
      company: @company,
      discount_type: "fixed",
      value: 20,
      priority: 10
    )

    result = PricingEngine.call(sellable: @sellable, user: user_no_company)

    assert_equal 100.00, result.price
    assert_nil result.applied_rule
  end

  test "does not apply company rule when company does not match" do
    other_company = Company.create!(name: "Other Corp", is_active: true)
    
    PricingRule.create!(
      sellable: @sellable,
      channel: "company",
      company: other_company,
      discount_type: "fixed",
      value: 20,
      priority: 10
    )

    result = PricingEngine.call(sellable: @sellable, user: @user)

    assert_equal 100.00, result.price
    assert_nil result.applied_rule
  end

  # === Sub-Company Channel Tests ===

  test "applies sub_company rule to parent company user" do
    rule = PricingRule.create!(
      sellable: @sellable,
      channel: "sub_company",
      company: @company,
      sub_company: @sub_company,
      discount_type: "percentage",
      value: 15,
      priority: 10
    )

    result = PricingEngine.call(sellable: @sellable, user: @user_sub)

    assert_equal 85.00, result.price
    assert_equal rule, result.applied_rule
  end

  # === Promo Code Tests ===

  test "applies promo code rule when code matches" do
    rule = PricingRule.create!(
      sellable: @sellable,
      channel: "promo",
      promo_code: "SAVE20",
      discount_type: "fixed",
      value: 20,
      priority: 100
    )

    result = PricingEngine.call(sellable: @sellable, promo_code: "SAVE20")

    assert_equal 80.00, result.price
    assert_equal rule, result.applied_rule
  end

  test "promo code is case insensitive" do
    rule = PricingRule.create!(
      sellable: @sellable,
      channel: "promo",
      promo_code: "SAVE20",
      discount_type: "fixed",
      value: 20,
      priority: 100
    )

    result = PricingEngine.call(sellable: @sellable, promo_code: "save20")

    assert_equal 80.00, result.price
    assert_equal rule, result.applied_rule
  end

  test "does not apply promo rule when code does not match" do
    PricingRule.create!(
      sellable: @sellable,
      channel: "promo",
      promo_code: "SAVE20",
      discount_type: "fixed",
      value: 20,
      priority: 100
    )

    result = PricingEngine.call(sellable: @sellable, promo_code: "WRONGCODE")

    assert_equal 100.00, result.price
    assert_nil result.applied_rule
  end

  # === Priority Tests ===

  test "applies highest priority rule first" do
    low_priority = PricingRule.create!(
      sellable: @sellable,
      channel: "public",
      discount_type: "percentage",
      value: 50,
      priority: 1
    )

    high_priority = PricingRule.create!(
      sellable: @sellable,
      channel: "public",
      discount_type: "fixed",
      value: 10,
      priority: 100
    )

    result = PricingEngine.call(sellable: @sellable)

    assert_equal 90.00, result.price
    assert_equal high_priority, result.applied_rule
  end

  # === Scope Specificity Tests ===

  test "variant-level rule overrides sellable-level rule" do
    sellable_rule = PricingRule.create!(
      sellable: @sellable,
      channel: "public",
      discount_type: "percentage",
      value: 20,
      priority: 10
    )

    variant_rule = PricingRule.create!(
      sellable_variant: @variant,
      channel: "public",
      discount_type: "fixed",
      value: 10,
      priority: 10
    )

    result = PricingEngine.call(sellable: @sellable, variant: @variant)

    assert_equal 140.00, result.price # 150 - 10
    assert_equal variant_rule, result.applied_rule
  end

  test "sellable-level rule overrides global rule" do
    global_rule = PricingRule.create!(
      sellable_id: nil,
      channel: "public",
      discount_type: "percentage",
      value: 50,
      priority: 10
    )

    sellable_rule = PricingRule.create!(
      sellable: @sellable,
      channel: "public",
      discount_type: "fixed",
      value: 5,
      priority: 10
    )

    result = PricingEngine.call(sellable: @sellable)

    assert_equal 95.00, result.price
    assert_equal sellable_rule, result.applied_rule
  end

  # === Discount Type Tests ===

  test "percentage discount reduces price by percentage" do
    PricingRule.create!(
      sellable: @sellable,
      channel: "public",
      discount_type: "percentage",
      value: 25,
      priority: 1
    )

    result = PricingEngine.call(sellable: @sellable)

    assert_equal 75.00, result.price
  end

  test "fixed discount subtracts fixed amount" do
    PricingRule.create!(
      sellable: @sellable,
      channel: "public",
      discount_type: "fixed",
      value: 30,
      priority: 1
    )

    result = PricingEngine.call(sellable: @sellable)

    assert_equal 70.00, result.price
  end

  test "override discount sets exact price" do
    PricingRule.create!(
      sellable: @sellable,
      channel: "public",
      discount_type: "override",
      value: 49.99,
      priority: 1
    )

    result = PricingEngine.call(sellable: @sellable)

    assert_equal 49.99, result.price
  end

  test "fixed discount never goes below zero" do
    PricingRule.create!(
      sellable: @sellable,
      channel: "public",
      discount_type: "fixed",
      value: 150, # More than base price
      priority: 1
    )

    result = PricingEngine.call(sellable: @sellable)

    assert_equal 0.00, result.price
  end

  # === Time Validity Tests ===

  test "applies rule within valid date range" do
    rule = PricingRule.create!(
      sellable: @sellable,
      channel: "public",
      discount_type: "percentage",
      value: 10,
      priority: 1,
      valid_from: 1.day.ago,
      valid_to: 1.day.from_now
    )

    result = PricingEngine.call(sellable: @sellable, context_date: Time.current)

    assert_equal 90.00, result.price
    assert_equal rule, result.applied_rule
  end

  test "does not apply rule before valid_from date" do
    PricingRule.create!(
      sellable: @sellable,
      channel: "public",
      discount_type: "percentage",
      value: 10,
      priority: 1,
      valid_from: 1.day.from_now,
      valid_to: 2.days.from_now
    )

    result = PricingEngine.call(sellable: @sellable, context_date: Time.current)

    assert_equal 100.00, result.price
    assert_nil result.applied_rule
  end

  test "does not apply rule after valid_to date" do
    PricingRule.create!(
      sellable: @sellable,
      channel: "public",
      discount_type: "percentage",
      value: 10,
      priority: 1,
      valid_from: 2.days.ago,
      valid_to: 1.day.ago
    )

    result = PricingEngine.call(sellable: @sellable, context_date: Time.current)

    assert_equal 100.00, result.price
    assert_nil result.applied_rule
  end

  test "applies rule with only valid_from" do
    rule = PricingRule.create!(
      sellable: @sellable,
      channel: "public",
      discount_type: "percentage",
      value: 10,
      priority: 1,
      valid_from: 1.day.ago,
      valid_to: nil
    )

    result = PricingEngine.call(sellable: @sellable, context_date: Time.current)

    assert_equal 90.00, result.price
    assert_equal rule, result.applied_rule
  end

  test "applies rule with only valid_to" do
    rule = PricingRule.create!(
      sellable: @sellable,
      channel: "public",
      discount_type: "percentage",
      value: 10,
      priority: 1,
      valid_from: nil,
      valid_to: 1.day.from_now
    )

    result = PricingEngine.call(sellable: @sellable, context_date: Time.current)

    assert_equal 90.00, result.price
    assert_equal rule, result.applied_rule
  end
end
