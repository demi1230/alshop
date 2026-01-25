# frozen_string_literal: true

# Example demonstrating Order lifecycle command integration
#
# Run with: bin/rails runner examples/order_lifecycle_example.rb
#

puts "=== Order Lifecycle Command Example ===\n\n"

# Setup
user = User.find_or_create_by!(email: "demo@example.com") do |u|
  u.password = "password123"
  u.role = "customer"
end

service = Sellable.find_or_create_by!(name: "Premium Consulting", sellable_type: "Service") do |s|
  s.base_price = 1000.00
  s.is_active = true
end

Service.find_or_create_by!(sellable: service) do |svc|
  svc.service_type = "hourly"
end

# Create order via cart
cart = Cart.create!(user: user, status: 'active')
CartItem.create!(
  cart: cart,
  sellable: service,
  quantity: 10, # 10 hours
  configuration: { project_type: "Web Application", tech_stack: "Rails + React" }
)

puts "1. Creating order from cart..."
cart_result = CartToOrderService.call(cart: cart, user: user)
order = cart_result.order
puts "   ✓ Order ##{order.id} created (status: #{order.status}, total: $#{order.total_price})"
puts

# Scenario 1: Normal payment flow
puts "2. Marking order as paid..."
paid_result = Orders::MarkPaid.call(
  order: order,
  payment_method: "stripe",
  transaction_id: "ch_#{SecureRandom.hex(12)}"
)

if paid_result.success?
  puts "   ✓ Order marked as paid"
  puts "   ✓ Event emitted: #{paid_result.event.event_type}"
  puts "   ✓ Fulfillments created: #{paid_result.fulfillments.count}"
  
  fulfillment = paid_result.fulfillments.first
  puts "   ✓ Fulfillment status: #{fulfillment.status}"
  puts "   ✓ Scheduled at: #{fulfillment.scheduled_at}"
else
  puts "   ✗ Failed: #{paid_result.errors.join(', ')}"
end
puts

# Scenario 2: Partial refund
puts "3. Processing partial refund (20%)..."
refund_result = Orders::Refund.call(
  order: order.reload,
  refund_amount: 200.00,
  reason: "First milestone not completed"
)

if refund_result.success?
  puts "   ✓ Refund processed"
  puts "   ✓ Event emitted: #{refund_result.event.event_type}"
  order.reload
  puts "   ✓ Total refunded: $#{order.metadata['total_refunded']}"
  puts "   ✓ Fully refunded: #{order.metadata['fully_refunded'] || false}"
else
  puts "   ✗ Failed: #{refund_result.errors.join(', ')}"
end
puts

# Scenario 3: Another partial refund
puts "4. Processing another partial refund (30%)..."
refund_result2 = Orders::Refund.call(
  order: order.reload,
  refund_amount: 300.00,
  reason: "Quality issues with deliverable"
)

if refund_result2.success?
  puts "   ✓ Second refund processed"
  order.reload
  puts "   ✓ Total refunded: $#{order.metadata['total_refunded']}"
  puts "   ✓ Number of refunds: #{order.metadata['refunds'].length}"
else
  puts "   ✗ Failed: #{refund_result2.errors.join(', ')}"
end
puts

# Scenario 4: Demonstrate idempotency
puts "5. Testing idempotency - marking paid order as paid again..."
idempotent_result = Orders::MarkPaid.call(
  order: order.reload,
  payment_method: "stripe"
)

if idempotent_result.success?
  puts "   ✓ Command succeeded (idempotent)"
  puts "   ✓ Event emitted: #{idempotent_result.event.inspect}"
  puts "   ✓ Fulfillments created: #{idempotent_result.fulfillments.count}"
else
  puts "   ✗ Failed: #{idempotent_result.errors.join(', ')}"
end
puts

# Scenario 5: Test invalid transition
puts "6. Creating new order for cancellation demo..."
cart2 = Cart.create!(user: user, status: 'active')
CartItem.create!(cart: cart2, sellable: service, quantity: 5)
order2 = CartToOrderService.call(cart: cart2, user: user).order
puts "   ✓ Order ##{order2.id} created"
puts

puts "7. Cancelling pending order..."
cancel_result = Orders::Cancel.call(
  order: order2,
  reason: "Customer changed mind",
  cancelled_by: user.id
)

if cancel_result.success?
  puts "   ✓ Order cancelled"
  puts "   ✓ Event emitted: #{cancel_result.event.event_type}"
  order2.reload
  puts "   ✓ Previous status: #{order2.metadata['previous_status']}"
  puts "   ✓ Cancellation reason: #{order2.metadata['cancellation_reason']}"
else
  puts "   ✗ Failed: #{cancel_result.errors.join(', ')}"
end
puts

puts "8. Attempting to mark cancelled order as paid (should fail)..."
invalid_result = Orders::MarkPaid.call(
  order: order2.reload,
  payment_method: "stripe"
)

if invalid_result.success?
  puts "   ✗ Should have failed but succeeded!"
else
  puts "   ✓ Failed as expected: #{invalid_result.errors.first}"
end
puts

# Summary
puts "=== Summary ==="
puts "Total orders created: 2"
puts "Order ##{order.id}: #{order.reload.status} (refunded $#{order.metadata['total_refunded']})"
puts "Order ##{order2.id}: #{order2.reload.status}"
puts "\nAll commands executed successfully!"
puts "\nCleanup: Orders and fulfillments remain in database for inspection."
