require "test_helper"

class Orders::RefundTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(
      email: "customer@test.com",
      password: "password123",
      role: "customer"
    )

    @order = Order.create!(
      user: @user,
      status: 'paid',
      total_price: 500.00,
      metadata: {
        payment_method: "credit_card",
        transaction_id: "txn_123",
        paid_at: 1.hour.ago.iso8601
      }
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

  test "refunds paid order" do
    result = Orders::Refund.call(
      order: @order,
      refund_amount: 500.00,
      reason: "Defective product",
      refund_method: "original_payment_method"
    )

    assert result.success?
  end

  test "refunds shipped order" do
    @order.update!(status: 'shipped')

    result = Orders::Refund.call(
      order: @order,
      refund_amount: 500.00,
      reason: "Customer return",
      refund_method: "original_payment_method"
    )

    assert result.success?
  end

  test "stores refund in metadata" do
    Orders::Refund.call(
      order: @order,
      refund_amount: 200.00,
      reason: "Partial refund",
      refund_method: "store_credit"
    )

    @order.reload
    refunds = @order.metadata["refunds"]
    
    assert_equal 1, refunds.length
    assert_equal 200.00, refunds.first["amount"]
    assert_equal "Partial refund", refunds.first["reason"]
    assert_equal "store_credit", refunds.first["refund_method"]
    assert_not_nil refunds.first["refunded_at"]
  end

  test "tracks total refunded amount" do
    Orders::Refund.call(
      order: @order,
      refund_amount: 200.00,
      reason: "Partial"
    )

    @order.reload
    assert_equal 200.00, @order.metadata["total_refunded"]
  end

  test "marks as fully refunded when total matches" do
    Orders::Refund.call(
      order: @order,
      refund_amount: 500.00,
      reason: "Full refund"
    )

    @order.reload
    assert @order.metadata["fully_refunded"]
    assert_not_nil @order.metadata["fully_refunded_at"]
  end

  test "emits OrderRefunded event" do
    result = Orders::Refund.call(
      order: @order,
      refund_amount: 300.00,
      reason: "Damaged item",
      refund_method: "credit_card"
    )

    assert_not_nil result.event
    assert_instance_of Orders::Events::OrderRefunded, result.event
    assert_equal @order.id, result.event.aggregate_id
    assert_equal 300.00, result.event.event_data[:refund_amount]
    assert_equal 500.00, result.event.event_data[:original_amount]
    assert_equal "Damaged item", result.event.event_data[:reason]
  end

  # === Partial Refunds ===

  test "supports partial refunds" do
    result = Orders::Refund.call(
      order: @order,
      refund_amount: 100.00,
      reason: "Partial refund"
    )

    assert result.success?
    @order.reload
    assert_equal 100.00, @order.metadata["total_refunded"]
    refute @order.metadata["fully_refunded"]
  end

  test "supports multiple partial refunds" do
    Orders::Refund.call(order: @order, refund_amount: 100.00, reason: "First refund")
    Orders::Refund.call(order: @order, refund_amount: 150.00, reason: "Second refund")
    Orders::Refund.call(order: @order, refund_amount: 250.00, reason: "Final refund")

    @order.reload
    assert_equal 3, @order.metadata["refunds"].length
    assert_equal 500.00, @order.metadata["total_refunded"]
    assert @order.metadata["fully_refunded"]
  end

  # === Invalid Transitions ===

  test "raises error when refunding pending order" do
    @order.update!(status: 'pending')

    result = Orders::Refund.call(
      order: @order,
      refund_amount: 100.00,
      reason: "Test"
    )

    assert result.failure?
    assert_includes result.errors.join, "Can only refund paid or shipped orders"
  end

  test "raises error when refunding cancelled order" do
    @order.update!(status: 'cancelled')

    result = Orders::Refund.call(
      order: @order,
      refund_amount: 100.00,
      reason: "Test"
    )

    assert result.failure?
    assert_includes result.errors.join, "Can only refund paid or shipped orders"
  end

  # === Validation ===

  test "fails when order is nil" do
    result = Orders::Refund.call(
      order: nil,
      refund_amount: 100.00,
      reason: "Test"
    )

    assert result.failure?
    assert_includes result.errors.join, "Order cannot be nil"
  end

  test "fails when reason is blank" do
    result = Orders::Refund.call(
      order: @order,
      refund_amount: 100.00,
      reason: ""
    )

    assert result.failure?
    assert_includes result.errors.join, "Refund reason is required"
  end

  test "fails when refund amount is nil" do
    result = Orders::Refund.call(
      order: @order,
      refund_amount: nil,
      reason: "Test"
    )

    assert result.failure?
    assert_includes result.errors.join, "Refund amount must be greater than zero"
  end

  test "fails when refund amount is zero" do
    result = Orders::Refund.call(
      order: @order,
      refund_amount: 0,
      reason: "Test"
    )

    assert result.failure?
    assert_includes result.errors.join, "Refund amount must be greater than zero"
  end

  test "fails when refund amount is negative" do
    result = Orders::Refund.call(
      order: @order,
      refund_amount: -50.00,
      reason: "Test"
    )

    assert result.failure?
    assert_includes result.errors.join, "Refund amount must be greater than zero"
  end

  test "fails when refund amount exceeds order total" do
    result = Orders::Refund.call(
      order: @order,
      refund_amount: 600.00,
      reason: "Too much"
    )

    assert result.failure?
    assert_includes result.errors.join, "Refund amount cannot exceed order total"
  end

  test "fails when total refunds would exceed order total" do
    # First refund
    Orders::Refund.call(
      order: @order,
      refund_amount: 400.00,
      reason: "First"
    )

    # Second refund that exceeds total
    result = Orders::Refund.call(
      order: @order,
      refund_amount: 200.00,
      reason: "Second"
    )

    assert result.failure?
    assert_includes result.errors.join, "Total refunds cannot exceed order total"
  end

  # === Event Structure ===

  test "event contains correct refund data" do
    result = Orders::Refund.call(
      order: @order,
      refund_amount: 250.00,
      reason: "Product damaged",
      refund_method: "paypal"
    )

    event_hash = result.event.to_h
    assert_equal "OrderRefunded", event_hash[:event_type]
    assert_equal @order.id, event_hash[:aggregate_id]
    assert_equal 250.00, event_hash[:event_data][:refund_amount]
    assert_equal 500.00, event_hash[:event_data][:original_amount]
    assert_equal "Product damaged", event_hash[:event_data][:reason]
    assert_equal "paypal", event_hash[:event_data][:refund_method]
    assert_equal @user.id, event_hash[:event_data][:user_id]
  end

  test "event is immutable" do
    result = Orders::Refund.call(
      order: @order,
      refund_amount: 100.00,
      reason: "Test"
    )

    assert_raises(FrozenError) do
      result.event.event_data[:refund_amount] = 200.00
    end
  end

  # === Edge Cases ===

  test "handles refund when metadata is nil" do
    @order.update!(metadata: nil)

    result = Orders::Refund.call(
      order: @order,
      refund_amount: 100.00,
      reason: "Test"
    )

    assert result.success?
    @order.reload
    assert_not_nil @order.metadata
    assert_equal 1, @order.metadata["refunds"].length
  end

  test "uses original payment method as default refund method" do
    result = Orders::Refund.call(
      order: @order,
      refund_amount: 100.00,
      reason: "Test"
    )

    @order.reload
    assert_equal "original_payment_method", @order.metadata["refunds"].first["refund_method"]
  end

  test "allows custom refund method" do
    result = Orders::Refund.call(
      order: @order,
      refund_amount: 100.00,
      reason: "Test",
      refund_method: "store_credit"
    )

    @order.reload
    assert_equal "store_credit", @order.metadata["refunds"].first["refund_method"]
  end
end
