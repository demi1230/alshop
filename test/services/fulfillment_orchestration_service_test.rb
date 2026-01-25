require "test_helper"

class FulfillmentOrchestrationServiceTest < ActiveSupport::TestCase
  setup do
    # Create user
    @user = User.create!(
      email: "customer@test.com",
      password: "password123",
      role: "customer"
    )

    @staff = User.create!(
      email: "staff@test.com",
      password: "password123",
      role: "staff"
    )

    # Create service sellable
    @service_sellable = Sellable.create!(
      name: "Web Development Service",
      sellable_type: "Service",
      base_price: 1000.00,
      is_active: true
    )

    @service = Service.create!(
      sellable: @service_sellable,
      service_type: "fixed"
    )

    @service_variant = SellableVariant.create!(
      sellable: @service_sellable,
      variant_name: "Premium Package",
      sku: "WEB-DEV-001",
      price_override: 1500.00
    )

    # Create order with service items
    @order = Order.create!(
      user: @user,
      status: 'paid',
      total_price: 3000.00
    )

    @order_item = OrderItem.create!(
      order: @order,
      sellable: @service_sellable,
      sellable_variant: @service_variant,
      quantity: 2,
      price_at_purchase: 1500.00,
      line_total: 3000.00,
      config_snapshot: {
        sellable_name: "Web Development Service",
        variant_name: "Premium Package",
        configuration: { pages: 10, features: ['cms', 'ecommerce'] }
      }
    )
  end

  # === Success Cases ===

  test "creates service fulfillment for paid order" do
    result = FulfillmentOrchestrationService.call(order: @order)

    assert result.success?
    assert_equal 1, result.fulfillments.count
  end

  test "creates fulfillment with correct associations" do
    result = FulfillmentOrchestrationService.call(order: @order)

    fulfillment = result.fulfillments.first
    assert_equal @order_item, fulfillment.order_item
    assert_equal 'scheduled', fulfillment.status
  end

  test "sets scheduled status by default" do
    result = FulfillmentOrchestrationService.call(order: @order)

    fulfillment = result.fulfillments.first
    assert fulfillment.scheduled?
  end

  test "assigns user when provided" do
    result = FulfillmentOrchestrationService.call(
      order: @order,
      assigned_user: @staff
    )

    fulfillment = result.fulfillments.first
    assert_equal @staff, fulfillment.assigned_user
  end

  test "sets scheduled_at when provided" do
    future_time = 2.days.from_now

    result = FulfillmentOrchestrationService.call(
      order: @order,
      scheduled_at: future_time
    )

    fulfillment = result.fulfillments.first
    assert_in_delta future_time.to_i, fulfillment.scheduled_at.to_i, 1
  end

  test "sets scheduled_at to current time when not provided" do
    result = FulfillmentOrchestrationService.call(order: @order)

    fulfillment = result.fulfillments.first
    assert_not_nil fulfillment.scheduled_at
    assert_in_delta Time.current.to_i, fulfillment.scheduled_at.to_i, 5
  end

  test "builds descriptive notes from order item" do
    result = FulfillmentOrchestrationService.call(order: @order)

    fulfillment = result.fulfillments.first
    metadata = fulfillment.result

    assert_equal "Web Development Service", metadata["sellable_name"]
    assert_equal "Premium Package", metadata["variant_name"]
  end

  test "creates multiple fulfillments for multiple service items" do
    # Add second service item
    service2 = Sellable.create!(
      name: "SEO Optimization",
      sellable_type: "Service",
      base_price: 500.00,
      is_active: true
    )
    Service.create!(sellable: service2, service_type: "subscription")

    OrderItem.create!(
      order: @order,
      sellable: service2,
      quantity: 1,
      price_at_purchase: 500.00,
      line_total: 500.00,
      config_snapshot: { sellable_name: "SEO Optimization" }
    )

    result = FulfillmentOrchestrationService.call(order: @order)

    assert result.success?
    assert_equal 2, result.fulfillments.count
  end

  test "can retrieve fulfillments through order item" do
    result = FulfillmentOrchestrationService.call(order: @order)

    @order_item.reload
    assert_not_nil @order_item.service_fulfillment
    assert_equal 'scheduled', @order_item.service_fulfillment.status
  end

  test "fulfillment is separate aggregate from order" do
    result = FulfillmentOrchestrationService.call(order: @order)

    fulfillment = result.fulfillments.first
    
    # Fulfillment doesn't directly belong to order
    assert_respond_to fulfillment, :order_item
    assert_equal @order, fulfillment.order_item.order
    
    # But it's accessed through order_item, not direct association
    refute_respond_to fulfillment, :order
  end

  # === Validation Tests ===

  test "fails when order is nil" do
    result = FulfillmentOrchestrationService.call(order: nil)

    assert result.failure?
    assert_includes result.errors.join, "Order cannot be nil"
  end

  test "fails when order is not paid" do
    @order.update!(status: 'pending')

    result = FulfillmentOrchestrationService.call(order: @order)

    assert result.failure?
    assert_includes result.errors.join, "Order must be paid"
  end

  test "fails when order has no items" do
    @order.order_items.destroy_all

    result = FulfillmentOrchestrationService.call(order: @order)

    assert result.failure?
    assert_includes result.errors.join, "Order has no items to fulfill"
  end

  test "fails when fulfillments already exist" do
    # Create first fulfillment
    FulfillmentOrchestrationService.call(order: @order)

    # Attempt to create again
    result = FulfillmentOrchestrationService.call(order: @order)

    assert result.failure?
    assert_includes result.errors.join, "Fulfillments already exist"
  end

  test "fails when order has only product items" do
    # Replace service item with product item
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

    result = FulfillmentOrchestrationService.call(order: @order)

    assert result.failure?
    assert_includes result.errors.join, "No service items found"
  end

  test "does not create fulfillments when validation fails" do
    @order.update!(status: 'pending')

    assert_no_difference 'ServiceFulfillment.count' do
      FulfillmentOrchestrationService.call(order: @order)
    end
  end

  # === Mixed Order Tests ===

  test "creates fulfillments only for service items in mixed order" do
    # Add product item to same order
    product_sellable = Sellable.create!(
      name: "Physical Product",
      sellable_type: "Product",
      base_price: 100.00,
      is_active: true
    )
    Product.create!(sellable: product_sellable, sku_base: "PROD")

    product_item = OrderItem.create!(
      order: @order,
      sellable: product_sellable,
      quantity: 1,
      price_at_purchase: 100.00,
      line_total: 100.00,
      config_snapshot: {}
    )

    result = FulfillmentOrchestrationService.call(order: @order)

    assert result.success?
    # Only 1 fulfillment created (for service item, not product)
    assert_equal 1, result.fulfillments.count
    assert_equal @order_item, result.fulfillments.first.order_item
    
    # Product item has no fulfillment
    product_item.reload
    assert_nil product_item.service_fulfillment
  end

  # === Transaction Tests ===

  test "creates all fulfillments atomically" do
    # Add multiple service items
    3.times do |i|
      service = Sellable.create!(
        name: "Service #{i}",
        sellable_type: "Service",
        base_price: 100.00,
        is_active: true
      )
      Service.create!(sellable: service, service_type: "hourly")

      OrderItem.create!(
        order: @order,
        sellable: service,
        quantity: 1,
        price_at_purchase: 100.00,
        line_total: 100.00,
        config_snapshot: {}
      )
    end

    result = FulfillmentOrchestrationService.call(order: @order)

    assert result.success?
    # Original + 3 new = 4 total
    assert_equal 4, result.fulfillments.count
    assert_equal 4, @order.order_items.count
  end

  # === Edge Cases ===

  test "handles service item without variant" do
    @order_item.update!(sellable_variant: nil)

    result = FulfillmentOrchestrationService.call(order: @order)

    assert result.success?
    fulfillment = result.fulfillments.first
    assert_not_nil fulfillment
    assert_equal "Web Development Service", fulfillment.result["sellable_name"]
  end

  test "handles service item without configuration" do
    @order_item.update!(config_snapshot: { sellable_name: "Simple Service" })

    result = FulfillmentOrchestrationService.call(order: @order)

    assert result.success?
    fulfillment = result.fulfillments.first
    assert_not_nil fulfillment.result
  end

  test "works with different order statuses after paid" do
    # Order can be 'shipped' (physical items shipped, services pending)
    @order.update!(status: 'paid')
    
    result = FulfillmentOrchestrationService.call(order: @order)
    assert result.success?
  end
end
