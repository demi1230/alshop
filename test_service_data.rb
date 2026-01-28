# Test Data Creation Script
# Run with: bin/rails runner test_service_data.rb

puts "="*50
puts "Creating test data for Service system..."
puts "="*50

# Find or create service category
service_category = Category.find_or_create_by!(name: "IT Services") do |c|
  c.parent = nil
end

# 1. Create Subscription Service with Plans
erp_sellable = Sellable.find_or_create_by!(name: "Enterprise ERP System") do |s|
  s.sellable_type = "Service"
  s.base_price = 5000000
  s.is_active = true
  s.description = "Иж бүрэн ERP систем - Accounting, HR, Inventory модультай"
end

erp_service = Service.find_or_create_by!(sellable: erp_sellable) do |srv|
  srv.category = service_category
  srv.service_type = "subscription"
  srv.requires_schedule = false
end

# Create default variant
unless erp_sellable.sellable_variants.exists?
  SellableVariant.create!(
    sellable: erp_sellable,
    variant_name: "Standard",
    sku: "ERP-STD-001",
    is_active: true
  )
end

# Create service config specs
ServiceConfigSpec.find_or_create_by!(
  service: erp_service,
  field_name: "User count"
) do |spec|
  spec.data_type = "int"
  spec.unit_price = 50000
  spec.description = "Хэрэглэгчийн тоо (хэрэглэгч бүр +50,000₮)"
end

ServiceConfigSpec.find_or_create_by!(
  service: erp_service,
  field_name: "Extra module"
) do |spec|
  spec.data_type = "bool"
  spec.unit_price = 300000
  spec.description = "Нэмэлт модуль идэвхжүүлэх (+300,000₮)"
end

# Create subscription plans
monthly_plan = SubscriptionPlan.find_or_create_by!(
  sellable: erp_sellable,
  billing_cycle: 'monthly',
  company: nil
) do |plan|
  plan.price = 5000000
  plan.trial_days = 7
end
puts "✓ Created monthly plan: #{monthly_plan.price}₮/сар"

yearly_plan = SubscriptionPlan.find_or_create_by!(
  sellable: erp_sellable,
  billing_cycle: 'yearly',
  company: nil
) do |plan|
  plan.price = 50000000
  plan.trial_days = 30
end
puts "✓ Created yearly plan: #{yearly_plan.price}₮/жил"

# 2. Create Hourly Service with Config
support_sellable = Sellable.find_or_create_by!(name: "IT Support & Maintenance") do |s|
  s.sellable_type = "Service"
  s.base_price = 120000
  s.is_active = true
  s.description = "Мэргэжлийн IT дэмжлэг болон засвар үйлчилгээ"
end

support_service = Service.find_or_create_by!(sellable: support_sellable) do |srv|
  srv.category = service_category
  srv.service_type = "hourly"
  srv.requires_schedule = true
end

# Create default variant
unless support_sellable.sellable_variants.exists?
  SellableVariant.create!(
    sellable: support_sellable,
    variant_name: "Standard",
    sku: "SUPPORT-STD-001",
    is_active: true
  )
end

# Create config with options
ServiceConfigSpec.find_or_create_by!(
  service: support_service,
  field_name: "Support Level"
) do |spec|
  spec.data_type = "string"
  spec.unit_price = 0
  spec.description = "Дэмжлэгийн түвшин сонгох"
  spec.options = [
    { "value" => "Standard", "price" => 0 },
    { "value" => "Premium", "price" => 60000 }
  ]
end
puts "✓ Created hourly service with config options"

# 3. Create Fixed Service
workshop_sellable = Sellable.find_or_create_by!(name: "Web Development Workshop") do |s|
  s.sellable_type = "Service"
  s.base_price = 350000
  s.is_active = true
  s.description = "3 хоногийн web хөгжүүлэлтийн сургалт"
end

workshop_service = Service.find_or_create_by!(sellable: workshop_sellable) do |srv|
  srv.category = service_category
  srv.service_type = "fixed"
  srv.requires_schedule = true
end

# Create default variant
unless workshop_sellable.sellable_variants.exists?
  SellableVariant.create!(
    sellable: workshop_sellable,
    variant_name: "Standard",
    sku: "WORKSHOP-001",
    is_active: true
  )
end
puts "✓ Created fixed price service"

puts "\n" + "="*50
puts "Test data creation complete!"
puts "="*50
puts "\nCreated services:"
puts "1. #{erp_sellable.name} (subscription) - #{erp_service.service_config_specs.count} config specs, #{erp_sellable.subscription_plans.count} plans"
puts "2. #{support_sellable.name} (hourly) - #{support_service.service_config_specs.count} config specs"
puts "3. #{workshop_sellable.name} (fixed)"
puts "\nYou can now test at:"
puts "- http://localhost:3000/services"
puts "- http://localhost:3000/services/#{erp_service.id}"
puts "- http://localhost:3000/services/#{support_service.id}"
puts "- http://localhost:3000/services/#{workshop_service.id}"
