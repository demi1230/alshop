require "test_helper"

class Orders::MarkPaidTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(
      email: "customer@test.com",
      password: "password123",
      role: "customer"
    )

    @service_sellable = Sellable.create!(
      name: "Consulting",
      sellable_type: "Service",
      base_price: 500.00,
      is_active: true
    )
    Service.create!(sellable: @service_sellable, service_type: "hourly")

    @order = Order.create!(
      user: @user,
      status: 'pending',
      total_price: 500.00
    )

    @order_item = OrderItem.create!(
      order: @order,
      sellable: @service_sellable,
      quantity: 1,
      price_at_purchase: 500.00,
      line_total: 500.00,
      config_snapshot: {}
    )
  end

  # === Valid Transitions ===

  test "marks pending order as paid" do
    result = Orders::MarkPaid.call(
      order: @order,
      payment_method: "credit_card",
      transaction_id: "txn_123"
    )

    assert result.success?
    @order.reload
    assert @order.paid?
  end

  test "stores payment metadata" do
    Orders::MarkPaid.call(
      order: @order,
      payment_method: "paypal",
      transaction_id: "pp_456"
    )

    @order.reload
    assert_equal "paypal", @order.metadata["payment_method"]
    assert_equal "pp_456", @order.metadata["transaction_id"]
    assert_not_nil @order.metadata["paid_at"]
  end

  test "emits OrderMarkedPaid event" do
    result = Orders::MarkPaid.call(
      order: @order,
      payment_method: "credit_card",
      transaction_id: "txn_123"
    )

    assert_not_nil result.event
    assert_instance_of Orders::Events::OrderMarkedPaid, result.event
    assert_equal @order.id, result.event.aggregate_id
    assert_equal 'Order', result.event.aggregate_type
    assert_equal "credit_card", result.event.event_data[:payment_method]
  end

  test "triggers fulfillment for service orders" do
    result = Orders::MarkPaid.call(
      order: @order,
      payment_method: "credit_card"
    )

    assert result.success?
    assert_equal 1, result.fulfillments.count
    assert_equal @order_item, result.fulfillments.first.order_item
  end

  test "does not trigger fulfillment for product-only orders" do
    @order_item.destroy

    product_sellable = Sellable.create!(
      name: "Product",
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

    result = Orders::MarkPaid.call(
      order: @order,
      payment_method: "credit_card"
    )

    assert result.success?
    assert_equal 0, result.fulfillments.count
  end

  # === Idempotency ===

  test "is idempotent - marking paid order as paid returns success" do
    # First payment
    Orders::MarkPaid.call(
      order: @order,
      payment_method: "credit_card",
      transaction_id: "txn_123"
    )

    # Second payment attempt
    result = Orders::MarkPaid.call(
      order: @order,
      payment_method: "credit_card",
      transaction_id: "txn_456"
    )

    assert result.success?
    assert_empty result.fulfillments
    assert_nil result.event
  end

  # === Invalid Transitions ===

  test "raises error when marking cancelled order as paid" do
    @order.update!(status: 'cancelled')

    result = Orders::MarkPaid.call(
      order: @order,
      payment_method: "credit_card"
    )

    assert result.failure?
    assert_includes result.errors.join, "Cannot mark cancelled order as paid"
  end

  test "returns custom error for invalid transition" do
    @order.update!(status: 'cancelled')

    result = Orders::MarkPaid.call(
      order: @order,
      payment_method: "credit_card"
    )

    assert result.failure?
    assert_match(/Cannot mark cancelled order as paid/, result.errors.first)
  end

  # === Validation ===

  test "fails when order is nil" do
    result = Orders::MarkPaid.call(
      order: nil,
      payment_method: "credit_card"
    )

    assert result.failure?
    assert_includes result.errors.join, "Order cannot be nil"
  end

  test "fails when order total is zero" do
    @order.update!(total_price: 0)

    result = Orders::MarkPaid.call(
      order: @order,
      payment_method: "credit_card"
    )

    assert result.failure?
    assert_includes result.errors.join, "Order total must be greater than zero"
  end

  # === Transaction Safety ===

  test "rolls back payment if fulfillment creation fails" do
    # Create fulfillment manually to trigger duplicate error
    ServiceFulfillment.create!(
      order_item: @order_item,
      status: 'scheduled',
      scheduled_at: Time.current
    )

    result = Orders::MarkPaid.call(
      order: @order,
      payment_method: "credit_card"
    )

    assert result.failure?
    @order.reload
    assert @order.pending?
  end

  # === Event Structure ===

  test "event contains correct order data" do
    result = Orders::MarkPaid.call(
      order: @order,
      payment_method: "stripe",
      transaction_id: "ch_abc"
    )

    event_hash = result.event.to_h
    assert_equal "OrderMarkedPaid", event_hash[:event_type]
    assert_equal @order.id, event_hash[:aggregate_id]
    assert_equal 500.00, event_hash[:event_data][:total_price]
    assert_equal "stripe", event_hash[:event_data][:payment_method]
    assert_equal "ch_abc", event_hash[:event_data][:transaction_id]
    assert_not_nil event_hash[:occurred_at]
  end

  test "event is immutable" do
    result = Orders::MarkPaid.call(
      order: @order,
      payment_method: "credit_card"
    )

    assert_raises(FrozenError) do
      result.event.event_data[:payment_method] = "paypal"
    end
  end
end
