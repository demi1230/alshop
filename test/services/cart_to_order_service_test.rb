require "test_helper"

class CartToOrderServiceTest < ActiveSupport::TestCase
  setup do
    # Create sellable with product
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

    @user = User.create!(
      email: "customer@test.com",
      password: "password123",
      role: "customer"
    )

    @cart = Cart.create!(
      user: @user,
      status: 'active'
    )

    @cart_item = CartItem.create!(
      cart: @cart,
      sellable: @sellable,
      sellable_variant: @variant,
      quantity: 2
    )
  end

  # === Success Cases ===

  test "creates order from cart successfully" do
    result = CartToOrderService.call(cart: @cart, user: @user)

    assert result.success?
    assert_not_nil result.order
    assert_equal 'pending', result.order.status
    assert_equal @user, result.order.user
  end

  test "creates order items with correct quantities" do
    result = CartToOrderService.call(cart: @cart, user: @user)

    assert_equal 1, result.order.order_items.count
    
    order_item = result.order.order_items.first
    assert_equal @sellable, order_item.sellable
    assert_equal @variant, order_item.sellable_variant
    assert_equal 2, order_item.quantity
  end

  test "snapshots prices at checkout time" do
    result = CartToOrderService.call(cart: @cart, user: @user)

    order_item = result.order.order_items.first
    assert_equal 150.00, order_item.price_at_purchase
    assert_equal 300.00, order_item.line_total # 150 * 2
  end

  test "applies pricing rules and snapshots discount" do
    PricingRule.create!(
      sellable: @sellable,
      channel: "public",
      discount_type: "percentage",
      value: 10,
      priority: 1
    )

    result = CartToOrderService.call(cart: @cart, user: @user)

    order_item = result.order.order_items.first
    assert_equal 135.00, order_item.price_at_purchase # 150 - 10%
    assert_equal 270.00, order_item.line_total # 135 * 2
  end

  test "applies promo code to all items" do
    PricingRule.create!(
      sellable: @sellable,
      channel: "promo",
      promo_code: "SAVE20",
      discount_type: "fixed",
      value: 20,
      priority: 100
    )

    result = CartToOrderService.call(
      cart: @cart,
      user: @user,
      promo_code: "SAVE20"
    )

    order_item = result.order.order_items.first
    assert_equal 130.00, order_item.price_at_purchase # 150 - 20
    assert_equal 260.00, order_item.line_total
  end

  test "calculates correct total price for order" do
    # Add another item
    sellable2 = Sellable.create!(
      name: "Product 2",
      sellable_type: "Product",
      base_price: 50.00,
      is_active: true
    )
    Product.create!(sellable: sellable2)
    
    CartItem.create!(
      cart: @cart,
      sellable: sellable2,
      quantity: 3
    )

    result = CartToOrderService.call(cart: @cart, user: @user)

    # Item 1: 150 * 2 = 300
    # Item 2: 50 * 3 = 150
    # Total: 450
    assert_equal 450.00, result.order.total_price
  end

  test "snapshots sellable configuration in order item" do
    result = CartToOrderService.call(cart: @cart, user: @user)

    order_item = result.order.order_items.first
    snapshot = order_item.config_snapshot
    
    assert_equal "Test Product", snapshot["sellable_name"]
    assert_equal "Product", snapshot["sellable_type"]
    assert_equal "Standard", snapshot["variant_name"]
    assert_equal "TEST-001", snapshot["variant_sku"]
    assert_equal 150.00, snapshot["base_price"].to_f
  end

  test "stores pricing rule information in snapshot" do
    rule = PricingRule.create!(
      sellable: @sellable,
      channel: "public",
      discount_type: "percentage",
      value: 10,
      priority: 1
    )

    result = CartToOrderService.call(cart: @cart, user: @user)

    snapshot = result.order.order_items.first.config_snapshot
    assert_equal rule.id, snapshot["applied_pricing_rule_id"]
    assert_equal 15.00, snapshot["discount_amount"].to_f
  end

  test "creates shipping address when params provided" do
    result = CartToOrderService.call(
      cart: @cart,
      user: @user,
      shipping_address_params: {
        city: "New York",
        district: "Manhattan",
        apartment_details: "Apt 5B",
        phone_number: "555-1234"
      }
    )

    assert_not_nil result.order.shipping_address
    assert_equal "New York", result.order.shipping_address.city
    assert_equal "555-1234", result.order.shipping_address.phone_number
  end

  test "marks cart as converted after successful order creation" do
    result = CartToOrderService.call(cart: @cart, user: @user)

    assert result.success?
    @cart.reload
    assert_equal 'converted', @cart.status
    assert @cart.converted?
  end

  test "works with guest user (no user)" do
    guest_cart = Cart.create!(status: 'active', session_id: 'guest123')
    CartItem.create!(
      cart: guest_cart,
      sellable: @sellable,
      quantity: 1
    )

    result = CartToOrderService.call(cart: guest_cart)

    assert result.success?
    assert_nil result.order.user
  end

  test "handles service configuration in cart item" do
    service_sellable = Sellable.create!(
      name: "ERP Software",
      sellable_type: "Service",
      base_price: 500.00,
      is_active: true
    )
    Service.create!(
      sellable: service_sellable,
      service_type: "subscription"
    )

    cart_item = CartItem.create!(
      cart: @cart,
      sellable: service_sellable,
      quantity: 1,
      configuration: { user_count: 50, modules: ['crm', 'inventory'] }
    )

    result = CartToOrderService.call(cart: @cart, user: @user)

    order_item = result.order.order_items.find_by(sellable: service_sellable)
    snapshot = order_item.config_snapshot
    
    assert_equal({ "user_count" => 50, "modules" => ['crm', 'inventory'] }, snapshot["configuration"])
  end

  # === Validation Tests ===

  test "fails when cart is nil" do
    result = CartToOrderService.call(cart: nil, user: @user)

    assert result.failure?
    assert_includes result.errors.join, "Cart cannot be nil"
  end

  test "fails when cart is not active" do
    @cart.update!(status: 'abandoned')

    result = CartToOrderService.call(cart: @cart, user: @user)

    assert result.failure?
    assert_includes result.errors.join, "Cart is not active"
  end

  test "fails when cart is empty" do
    @cart.cart_items.destroy_all

    result = CartToOrderService.call(cart: @cart, user: @user)

    assert result.failure?
    assert_includes result.errors.join, "Cart is empty"
  end

  test "fails when sellable is not active" do
    @sellable.update!(is_active: false)

    result = CartToOrderService.call(cart: @cart, user: @user)

    assert result.failure?
    assert_includes result.errors.join, "no longer available"
  end

  test "fails when variant is not active" do
    @variant.update!(is_active: false)

    result = CartToOrderService.call(cart: @cart, user: @user)

    assert result.failure?
    assert_includes result.errors.join, "no longer available"
  end

  test "fails when insufficient inventory" do
    Inventory.create!(
      sellable_variant: @variant,
      quantity: 1  # Cart has 2 items
    )

    result = CartToOrderService.call(cart: @cart, user: @user)

    assert result.failure?
    assert_includes result.errors.join, "Insufficient stock"
  end

  test "does not create order when validation fails" do
    @sellable.update!(is_active: false)

    assert_no_difference 'Order.count' do
      CartToOrderService.call(cart: @cart, user: @user)
    end
  end

  test "does not mark cart as converted when creation fails" do
    @sellable.update!(is_active: false)

    CartToOrderService.call(cart: @cart, user: @user)

    @cart.reload
    assert_equal 'active', @cart.status
  end

  # === Transaction Tests ===

  test "creates multiple order items atomically" do
    sellable2 = Sellable.create!(
      name: "Product 2",
      sellable_type: "Product",
      base_price: 50.00,
      is_active: true
    )
    Product.create!(sellable: sellable2)
    
    CartItem.create!(
      cart: @cart,
      sellable: sellable2,
      quantity: 1
    )

    result = CartToOrderService.call(cart: @cart, user: @user)

    assert result.success?
    assert_equal 2, result.order.order_items.count
  end

  # === Edge Cases ===

  test "handles cart item without variant" do
    CartItem.create!(
      cart: @cart,
      sellable: @sellable,
      sellable_variant: nil,
      quantity: 1
    )

    result = CartToOrderService.call(cart: @cart, user: @user)

    assert result.success?
    order_item = result.order.order_items.find_by(sellable_variant: nil)
    assert_not_nil order_item
    assert_equal 100.00, order_item.price_at_purchase # Uses base price
  end

  test "handles decimal quantities correctly" do
    # Some items might be sold by weight
    @cart_item.update!(quantity: 2)

    result = CartToOrderService.call(cart: @cart, user: @user)

    order_item = result.order.order_items.first
    assert_equal 300.00, order_item.line_total.round(2)
  end

  test "stores metadata in order" do
    result = CartToOrderService.call(
      cart: @cart,
      user: @user,
      promo_code: "TEST123"
    )

    metadata = result.order.metadata
    assert_equal @cart.id, metadata["cart_id"]
    assert_equal "TEST123", metadata["promo_code"]
    assert_equal "CartToOrderService", metadata["created_via"]
  end
end
