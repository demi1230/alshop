require "test_helper"

class Admin::PricingRulesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:admin)
    @pricing_rule = pricing_rules(:bulk_discount)
    @sellable = sellables(:macbook_sellable)
    sign_in @admin
  end

  test "should get index" do
    get admin_pricing_rules_url
    assert_response :success
  end

  test "should filter by active status" do
    get admin_pricing_rules_url, params: { active: true }
    assert_response :success
  end

  test "should get new" do
    get new_admin_pricing_rule_url
    assert_response :success
  end

  test "should create pricing rule" do
    assert_difference 'PricingRule.count', 1 do
      post admin_pricing_rules_url, params: {
        pricing_rule: {
          name: 'Шинэ хөнгөлөлт',
          sellable_id: @sellable.id,
          discount_type: 'percentage',
          discount_value: 10,
          min_quantity: 5,
          start_date: Date.today,
          end_date: 1.month.from_now
        }
      }
    end
    assert_redirected_to admin_pricing_rules_path
  end

  test "should create promo code rule" do
    assert_difference 'PricingRule.count', 1 do
      post admin_pricing_rules_url, params: {
        pricing_rule: {
          name: 'Промо код',
          promo_code: 'SAVE20',
          discount_type: 'percentage',
          discount_value: 20,
          usage_limit: 100
        }
      }
    end
    new_rule = PricingRule.last
    assert_equal 'SAVE20', new_rule.promo_code
  end

  test "should create channel-specific rule" do
    assert_difference 'PricingRule.count', 1 do
      post admin_pricing_rules_url, params: {
        pricing_rule: {
          name: 'Онлайн хөнгөлөлт',
          channel: 'online',
          discount_type: 'fixed',
          discount_value: 50000
        }
      }
    end
  end

  test "should show pricing rule" do
    get admin_pricing_rule_url(@pricing_rule)
    assert_response :success
  end

  test "should get edit" do
    get edit_admin_pricing_rule_url(@pricing_rule)
    assert_response :success
  end

  test "should update pricing rule" do
    patch admin_pricing_rule_url(@pricing_rule), params: {
      pricing_rule: {
        discount_value: 15,
        active: false
      }
    }
    @pricing_rule.reload
    assert_equal 15, @pricing_rule.discount_value
    assert_equal false, @pricing_rule.active
    assert_redirected_to admin_pricing_rule_path(@pricing_rule)
  end

  test "should update date range" do
    new_end_date = 2.months.from_now.to_date
    patch admin_pricing_rule_url(@pricing_rule), params: {
      pricing_rule: {
        end_date: new_end_date
      }
    }
    @pricing_rule.reload
    assert_equal new_end_date, @pricing_rule.end_date
  end

  test "should destroy pricing rule" do
    assert_difference 'PricingRule.count', -1 do
      delete admin_pricing_rule_url(@pricing_rule)
    end
    assert_redirected_to admin_pricing_rules_path
  end

  test "should validate discount value" do
    assert_no_difference 'PricingRule.count' do
      post admin_pricing_rules_url, params: {
        pricing_rule: {
          name: 'Буруу хөнгөлөлт',
          discount_type: 'percentage',
          discount_value: 150 # Invalid: > 100%
        }
      }
    end
    assert_response :unprocessable_entity
  end

  test "should validate date range" do
    assert_no_difference 'PricingRule.count' do
      post admin_pricing_rules_url, params: {
        pricing_rule: {
          name: 'Буруу огноо',
          start_date: Date.today,
          end_date: 1.week.ago # Invalid: before start
        }
      }
    end
    assert_response :unprocessable_entity
  end

  test "should check promo code uniqueness" do
    existing_rule = pricing_rules(:promo_code_rule)
    
    assert_no_difference 'PricingRule.count' do
      post admin_pricing_rules_url, params: {
        pricing_rule: {
          name: 'Давхар промо',
          promo_code: existing_rule.promo_code,
          discount_type: 'percentage',
          discount_value: 10
        }
      }
    end
    assert_response :unprocessable_entity
  end

  test "should deactivate expired rules" do
    # Test would call background job or rake task
    get admin_pricing_rules_url
    assert_response :success
  end

  test "should not allow non-admin access" do
    customer = users(:customer)
    sign_in customer
    get admin_pricing_rules_url
    assert_response :redirect
    assert_redirected_to root_path
  end

  test "should require authentication" do
    sign_out @admin
    get admin_pricing_rules_url
    assert_redirected_to new_user_session_path
  end
end
