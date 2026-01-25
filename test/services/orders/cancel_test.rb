require "test_helper"

class Orders::CancelTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(
      email: "customer@test.com",
      password: "password123",
      role: "customer"
    )

    @order = Order.create!(
      user: @user,
      status: 'pending',
      total_price: 500.00
    )

    @sellable = Sellable.create!(
      name: "Test Product",
      sellable_type: "Product",
      base_price: 500.00,
      is_active: true
    )
    Product.create!(sellable: @sellable, sku_base: "TEST")

    @order_item = OrderItem.create!(
      order: @order,
      sellable: @sellable,
      quantity: 1,
      price_at_purchase: 500.00,
      line_total: 500.00,
      config_snapshot: {}
    )
  end

  # === Valid Transitions ===

  test "cancels pending order" do
    result = Orders::Cancel.call(
      order: @order,
      reason: "Customer request",
      cancelled_by: @user.id
    )

    assert result.success?
    @order.reload
    assert @order.cancelled?
  end

  test "cancels paid order" do
    @order.update!(status: 'paid')

    result = Orders::Cancel.call(
      order: @order,
      reason: "Refund requested",
      cancelled_by: @user.id
    )

    assert result.success?
    @order.reload
    assert @order.cancelled?
  end

  test "stores cancellation metadata" do
    Orders::Cancel.call(
      order: @order,
      reason: "Out of stock",
      cancelled_by: @user.id
    )

    @order.reload
    assert_equal "Out of stock", @order.metadata["cancellation_reason"]
    assert_equal @user.id, @order.metadata["cancelled_by"]
    assert_equal "pending", @order.metadata["previous_status"]
    assert_not_nil @order.metadata["cancelled_at"]
  end

  test "emits OrderCancelled event" do
    result = Orders::Cancel.call(
      order: @order,
      reason: "Customer request",
      cancelled_by: @user.id
    )

    assert_not_nil result.event
    assert_instance_of Orders::Events::OrderCancelled, result.event
    assert_equal @order.id, result.event.aggregate_id
    assert_equal "Customer request", result.event.event_data[:reason]
    assert_equal @user.id, result.event.event_data[:cancelled_by]
  end

  # === Fulfillment Cancellation ===

  test "cancels associated service fulfillments when order is paid" do
    service_sellable = Sellable.create!(
      name: "Service",
      sellable_type: "Service",
      base_price: 100.00,
      is_active: true
    )
    Service.create!(sellable: service_sellable, service_type: "fixed")

    service_item = OrderItem.create!(
      order: @order,
      sellable: service_sellable,
      quantity: 1,
      price_at_purchase: 100.00,
      line_total: 100.00,
      config_snapshot: {}
    )

    # Mark order as paid and create fulfillment
    @order.update!(status: 'paid')
    fulfillment = ServiceFulfillment.create!(
      order_item: service_item,
      status: 'scheduled',
      scheduled_at: Time.current
    )

    # Cancel order
    Orders::Cancel.call(
      order: @order,
      reason: "Customer request",
      cancelled_by: @user.id
    )

    fulfillment.reload
    assert fulfillment.cancelled?
  end

  test "does not affect fulfillments from other orders" do
    # Create another order with fulfillment
    other_order = Order.create!(user: @user, status: 'paid', total_price: 100.00)
    
    service_sellable = Sellable.create!(
      name: "Service",
      sellable_type: "Service",
      base_price: 100.00,
      is_active: true
    )
    Service.create!(sellable: service_sellable, service_type: "fixed")

    other_item = OrderItem.create!(
      order: other_order,
      sellable: service_sellable,
      quantity: 1,
      price_at_purchase: 100.00,
      line_total: 100.00,
      config_snapshot: {}
    )

    other_fulfillment = ServiceFulfillment.create!(
      order_item: other_item,
      status: 'scheduled',
      scheduled_at: Time.current
    )

    # Cancel our order (not the other one)
    Orders::Cancel.call(
      order: @order,
      reason: "Test",
      cancelled_by: @user.id
    )

    other_fulfillment.reload
    assert other_fulfillment.scheduled?, "Other order's fulfillment should not be affected"
  end

  # === Idempotency ===

  test "is idempotent - cancelling cancelled order returns success" do
    Orders::Cancel.call(
      order: @order,
      reason: "First cancellation",
      cancelled_by: @user.id
    )

    result = Orders::Cancel.call(
      order: @order,
      reason: "Second cancellation",
      cancelled_by: @user.id
    )

    assert result.success?
    assert_nil result.event
  end

  # === Invalid Transitions ===

  test "raises error when cancelling shipped order" do
    @order.update!(status: 'shipped')

    result = Orders::Cancel.call(
      order: @order,
      reason: "Too late",
      cancelled_by: @user.id
    )

    assert result.failure?
    assert_includes result.errors.join, "Cannot cancel order that has been shipped"
  end

  # === Validation ===

  test "fails when order is nil" do
    result = Orders::Cancel.call(
      order: nil,
      reason: "Test"
    )

    assert result.failure?
    assert_includes result.errors.join, "Order cannot be nil"
  end

  test "fails when reason is blank" do
    result = Orders::Cancel.call(
      order: @order,
      reason: ""
    )

    assert result.failure?
    assert_includes result.errors.join, "Cancellation reason is required"
  end

  test "fails when reason is nil" do
    result = Orders::Cancel.call(
      order: @order,
      reason: nil
    )

    assert result.failure?
    assert_includes result.errors.join, "Cancellation reason is required"
  end

  # === Event Structure ===

  test "event contains correct cancellation data" do
    result = Orders::Cancel.call(
      order: @order,
      reason: "Customer changed mind",
      cancelled_by: @user.id
    )

    event_hash = result.event.to_h
    assert_equal "OrderCancelled", event_hash[:event_type]
    assert_equal @order.id, event_hash[:aggregate_id]
    assert_equal "Customer changed mind", event_hash[:event_data][:reason]
    assert_equal "pending", event_hash[:event_data][:previous_status]
    assert_equal 500.00, event_hash[:event_data][:total_price]
  end

  test "event is immutable" do
    result = Orders::Cancel.call(
      order: @order,
      reason: "Test",
      cancelled_by: @user.id
    )

    assert_raises(FrozenError) do
      result.event.event_data[:reason] = "Changed"
    end
  end
end
