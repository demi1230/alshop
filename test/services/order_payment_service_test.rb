require "test_helper"

class OrderPaymentServiceTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(
      email: "customer@test.com",
      password: "password123",
      role: "customer"
    )

    @service_sellable = Sellable.create!(
      name: "Consulting Service",
      sellable_type: "Service",
      base_price: 500.00,
      is_active: true
    )

    Service.create!(
      sellable: @service_sellable,
      service_type: "hourly"
    )

    @order = Order.create!(
      user: @user,
      status: 'pending',
      total_price: 500.00,
      metadata: {}
    )

    @order_item = OrderItem.create!(
      order: @order,
      sellable: @service_sellable,
      quantity: 1,
      price_at_purchase: 500.00,
      line_total: 500.00,
      config_snapshot: { sellable_name: "Consulting Service" }
    )
  end

  test "marks order as paid" do
    result = OrderPaymentService.call(
      order: @order,
      payment_method: "credit_card",
      transaction_id: "txn_123"
    )

    assert result.success?
    @order.reload
    assert @order.paid?
  end

  test "stores payment metadata" do
    result = OrderPaymentService.call(
      order: @order,
      payment_method: "paypal",
      transaction_id: "pp_456"
    )

    @order.reload
    assert_equal "paypal", @order.metadata["payment_method"]
    assert_equal "pp_456", @order.metadata["transaction_id"]
    assert_not_nil @order.metadata["paid_at"]
  end

  test "creates service fulfillments after payment" do
    result = OrderPaymentService.call(
      order: @order,
      payment_method: "credit_card"
    )

    assert result.success?
    assert_equal 1, result.fulfillments.count
    assert_equal @order_item, result.fulfillments.first.order_item
  end

  test "does not create fulfillments for product-only orders" do
    # Replace service with product
    @order_item.destroy

    product_sellable = Sellable.create!(
      name: "Physical Product",
      sellable_type: "Product",
      base_price: 100.00,
      is_active: true
    )
    Product.create!(sellable: product_sellable, sku_base: "PROD")

    OrderItem.create!(
      order: @order,
      sellable: product_sellable,
      quantity: 1,
      price_at_purchase: 100.00,
      line_total: 100.00,
      config_snapshot: {}
    )

    result = OrderPaymentService.call(
      order: @order,
      payment_method: "credit_card"
    )

    assert result.success?
    assert_equal 0, result.fulfillments.count
    assert @order.reload.paid?
  end

  test "fails when order is not pending" do
    @order.update!(status: 'paid')

    result = OrderPaymentService.call(
      order: @order,
      payment_method: "credit_card"
    )

    assert result.failure?
    assert_includes result.errors.join, "must be in pending status"
  end

  test "rolls back payment if fulfillment creation fails" do
    # Create fulfillment manually to trigger "already exists" error
    ServiceFulfillment.create!(
      order_item: @order_item,
      status: 'scheduled',
      scheduled_at: Time.current
    )

    result = OrderPaymentService.call(
      order: @order,
      payment_method: "credit_card"
    )

    assert result.failure?
    @order.reload
    assert @order.pending?, "Order should remain pending if fulfillment fails"
  end

  test "processes mixed orders with services and products" do
    # Add product item
    product_sellable = Sellable.create!(
      name: "Physical Product",
      sellable_type: "Product",
      base_price: 100.00,
      is_active: true
    )
    Product.create!(sellable: product_sellable, sku_base: "PROD")

    OrderItem.create!(
      order: @order,
      sellable: product_sellable,
      quantity: 1,
      price_at_purchase: 100.00,
      line_total: 100.00,
      config_snapshot: {}
    )

    result = OrderPaymentService.call(
      order: @order,
      payment_method: "credit_card"
    )

    assert result.success?
    # Only service item gets fulfillment
    assert_equal 1, result.fulfillments.count
    assert_equal @order_item, result.fulfillments.first.order_item
  end
end
