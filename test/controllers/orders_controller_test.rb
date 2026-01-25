require "test_helper"

class OrdersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:customer)
    @order = orders(:customer_order)
    sign_in @user
  end

  test "should get index" do
    get orders_url
    assert_response :success
  end

  test "should get index as json" do
    get orders_url, as: :json
    assert_response :success
    json_response = JSON.parse(response.body)
    assert json_response.is_a?(Array)
  end

  test "should show order" do
    get order_url(@order)
    assert_response :success
  end

  test "should show order as json" do
    get order_url(@order), as: :json
    assert_response :success
    json_response = JSON.parse(response.body)
    assert json_response.key?('id')
    assert json_response.key?('order_number')
    assert json_response.key?('items')
  end

  test "should not show other user order" do
    other_order = orders(:admin_order)
    get order_url(other_order)
    assert_response :redirect
  end

  test "should create order from cart" do
    cart = @user.cart
    cart_item = cart.cart_items.create!(
      sellable_variant: sellable_variants(:macbook_512gb),
      quantity: 1
    )

    # Mock CartToOrderService
    CartToOrderService.stub :call, OpenStruct.new(success?: true, order: @order) do
      assert_difference 'Order.count', 0 do # Not creating new, using mock
        post orders_url, params: { 
          order: { 
            shipping_address: { city: 'UB' },
            billing_address: { city: 'UB' },
            notes: 'Test order'
          } 
        }
      end
      assert_redirected_to order_path(@order)
    end
  end

  test "should not create order with empty cart" do
    @user.cart.cart_items.destroy_all
    
    post orders_url, params: { 
      order: { 
        shipping_address: { city: 'UB' }
      } 
    }
    assert_redirected_to cart_path
  end

  test "should require authentication" do
    sign_out @user
    get orders_url
    assert_redirected_to new_user_session_path
  end
end
