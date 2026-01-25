require "test_helper"

class SubscriptionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:customer)
    @subscription = user_subscriptions(:active_subscription)
    @plan = subscription_plans(:monthly_plan)
    sign_in @user
  end

  test "should get index" do
    get subscriptions_url
    assert_response :success
  end

  test "should get index as json" do
    get subscriptions_url, as: :json
    assert_response :success
    json_response = JSON.parse(response.body)
    assert json_response.is_a?(Array)
  end

  test "should create subscription" do
    assert_difference 'UserSubscription.count', 1 do
      post subscriptions_url, params: { 
        subscription_plan_id: @plan.id 
      }
    end
    assert_redirected_to subscriptions_path
  end

  test "should create subscription as json" do
    assert_difference 'UserSubscription.count', 1 do
      post subscriptions_url, params: { 
        subscription_plan_id: @plan.id 
      }, as: :json
    end
    assert_response :created
    json_response = JSON.parse(response.body)
    assert json_response['success']
    assert json_response.key?('subscription')
  end

  test "should not create duplicate active subscription" do
    # User already has active subscription in fixtures
    post subscriptions_url, params: { 
      subscription_plan_id: @plan.id 
    }
    assert_response :unprocessable_entity
  end

  test "should cancel subscription" do
    patch cancel_subscription_url(@subscription)
    @subscription.reload
    assert_equal 'cancelled', @subscription.status
    assert_redirected_to subscriptions_path
  end

  test "should cancel subscription as json" do
    patch cancel_subscription_url(@subscription), as: :json
    assert_response :success
    json_response = JSON.parse(response.body)
    assert json_response['success']
  end

  test "should not cancel other user subscription" do
    other_subscription = user_subscriptions(:staff_subscription)
    patch cancel_subscription_url(other_subscription)
    assert_response :redirect
  end

  test "should require authentication" do
    sign_out @user
    get subscriptions_url
    assert_redirected_to new_user_session_path
  end
end
