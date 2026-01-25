require "test_helper"

class CartsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:customer)
    @cart = carts(:customer_cart)
    sign_in @user
  end

  test "should get show" do
    get cart_url, as: :json
    assert_response :success
  end

  test "should get show as json" do
    get cart_url, as: :json
    assert_response :success
    json_response = JSON.parse(response.body)
    assert json_response.key?('id')
    assert json_response.key?('items')
    assert json_response.key?('total')
  end

  test "should clear cart" do
    assert_difference '@cart.cart_items.count', -@cart.cart_items.count do
      delete clear_cart_url, as: :json
    end
    assert_response :success
  end

  test "should clear cart via json" do
    delete clear_cart_url, as: :json
    assert_response :success
    json_response = JSON.parse(response.body)
    assert json_response['success']
  end
end
