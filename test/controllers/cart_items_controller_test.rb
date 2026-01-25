require "test_helper"

class CartItemsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:customer)
    @cart = carts(:customer_cart)
    @variant = sellable_variants(:macbook_1tb)
    @existing_item = cart_items(:customer_cart_item)
    sign_in @user
  end

  test "should create cart item" do
    assert_difference 'CartItem.count', 1 do
      post cart_items_url, params: { 
        cart_item: { 
          sellable_variant_id: @variant.id, 
          quantity: 2 
        } 
      }
    end
    assert_redirected_to cart_path
  end

  test "should create cart item via json" do
    assert_difference 'CartItem.count', 1 do
      post cart_items_url, params: { 
        cart_item: { 
          sellable_variant_id: @variant.id, 
          quantity: 1 
        } 
      }, as: :json
    end
    assert_response :created
    json_response = JSON.parse(response.body)
    assert json_response['success']
    assert json_response.key?('cart_count')
  end

  test "should update cart item quantity" do
    cart_item = cart_items(:customer_cart_item)
    patch cart_item_url(cart_item), params: { 
      cart_item: { quantity: 5 } 
    }
    assert_redirected_to cart_path
    assert_equal 5, cart_item.reload.quantity
  end

  test "should destroy cart item" do
    cart_item = cart_items(:customer_cart_item)
    assert_difference 'CartItem.count', -1 do
      delete cart_item_url(cart_item)
    end
    assert_redirected_to cart_path
  end

  test "should destroy cart item via json" do
    cart_item = cart_items(:customer_cart_item)
    assert_difference 'CartItem.count', -1 do
      delete cart_item_url(cart_item), as: :json
    end
    assert_response :success
    json_response = JSON.parse(response.body)
    assert json_response['success']
  end
end
