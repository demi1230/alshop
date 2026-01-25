# -----------------------------
# BRANDS
# -----------------------------
apple = Brand.find_or_create_by!(name: "Apple (TBG)") { |b| b.website_url = "https://apple.com" }
toyota = Brand.find_or_create_by!(name: "Toyota Mongolia (TBG)") { |b| b.website_url = "https://toyota.mn" }
gobi = Brand.find_or_create_by!(name: "GOBI Cashmere") { |b| b.website_url = "https://gobi.mn" }
kfc = Brand.find_or_create_by!(name: "KFC Mongolia") { |b| b.website_url = "https://kfc.mn" }
xerox = Brand.find_or_create_by!(name: "Xerox (TBG)") { |b| b.website_url = "" }

# -----------------------------
# CATEGORIES (hierarchical)
# -----------------------------
electronics = Category.find_or_create_by!(name: "Electronics", parent_id: nil)
computers = Category.find_or_create_by!(name: "Computers", parent_id: electronics.id)
laptops = Category.find_or_create_by!(name: "Laptops", parent_id: computers.id)

auto = Category.find_or_create_by!(name: "Automobiles", parent_id: nil)
clothing = Category.find_or_create_by!(name: "Clothing", parent_id: nil)
food = Category.find_or_create_by!(name: "Food & Beverages", parent_id: nil)
office = Category.find_or_create_by!(name: "Office Products", parent_id: nil)

service_cat = Category.find_or_create_by!(name: "Services", parent_id: nil)
erp_cat = Category.find_or_create_by!(name: "ERP Services", parent_id: service_cat.id)
auto_service_cat = Category.find_or_create_by!(name: "Automotive Services", parent_id: service_cat.id)  # ✅ ШИНЭ

# -----------------------------
# SELLABLES & PRODUCTS
# -----------------------------

# iPhone (leaf: Laptops)
iphone = Sellable.find_or_create_by!(name: "iPhone 15 TBG Edition") do |s|
  s.sellable_type = "Product"
  s.base_price = 1299
  s.is_active = true
end
Product.find_or_create_by!(sellable: iphone) do |p|
  p.category_id = laptops.id
  p.brand_id = apple.id
end
SellableVariant.find_or_create_by!(sellable: iphone, sku: "TBG-IPH15-BLK") do |v|
  v.variant_name = "Black 128GB"
  v.variant_type = "product"
  v.price_override = 0
end
SellableVariant.find_or_create_by!(sellable: iphone, sku: "TBG-IPH15-WHT") do |v|
  v.variant_name = "White 256GB"
  v.variant_type = "product"
  v.price_override = 100
end

# Toyota Corolla (leaf: Automobiles)
toyota_corolla = Sellable.find_or_create_by!(name: "Toyota Corolla (TBG)") do |s|
  s.sellable_type = "Product"
  s.base_price = 25000
  s.is_active = true
end
Product.find_or_create_by!(sellable: toyota_corolla) do |p|
  p.category_id = auto.id
  p.brand_id = toyota.id
end
SellableVariant.find_or_create_by!(sellable: toyota_corolla, sku: "TBG-TCOR-STD") do |v|
  v.variant_name = "Standard Sedan"
  v.variant_type = "product"
  v.price_override = 0
end
SellableVariant.find_or_create_by!(sellable: toyota_corolla, sku: "TBG-TCOR-LUX") do |v|
  v.variant_name = "Luxury Sedan"
  v.variant_type = "product"
  v.price_override = 5000
end

# GOBI Cashmere (leaf: Clothing)
gobi_scarf = Sellable.find_or_create_by!(name: "GOBI Cashmere Scarf") do |s|
  s.sellable_type = "Product"
  s.base_price = 129
  s.is_active = true
end
Product.find_or_create_by!(sellable: gobi_scarf) do |p|
  p.category_id = clothing.id
  p.brand_id = gobi.id
end
SellableVariant.find_or_create_by!(sellable: gobi_scarf, sku: "GOBI-SCARF-01") do |v|
  v.variant_name = "Grey"
  v.variant_type = "product"
  v.price_override = 0
end
SellableVariant.find_or_create_by!(sellable: gobi_scarf, sku: "GOBI-SCARF-02") do |v|
  v.variant_name = "Beige"
  v.variant_type = "product"
  v.price_override = 10
end

# -----------------------------
# SERVICES
# -----------------------------

# Toyota Service (✅ ЗАСАГДСАН: leaf категори auto_service_cat)
toyota_service = Sellable.find_or_create_by!(name: "Toyota Full Service") do |s|
  s.sellable_type = "Service"
  s.base_price = 120
  s.is_active = true
end
Service.find_or_create_by!(sellable: toyota_service) do |srv|
  srv.category_id = auto_service_cat.id  # ✅ ӨМНӨ: service_cat.id (parent)
  srv.service_type = "fixed"
  srv.requires_schedule = true
end
SellableVariant.find_or_create_by!(sellable: toyota_service, sku: "TBG-TY-SVC") do |v|
  v.variant_name = "Full Car Service"
  v.variant_type = "service"
  v.price_override = 0
end

# ERP Service (leaf: ERP Services)
erp_service = Sellable.find_or_create_by!(name: "ERP Enterprise Package") do |s|
  s.sellable_type = "Service"
  s.base_price = 1000
  s.is_active = true
end
Service.find_or_create_by!(sellable: erp_service) do |srv|
  srv.category_id = erp_cat.id
  srv.service_type = "subscription"
  srv.requires_schedule = false
end
SellableVariant.find_or_create_by!(sellable: erp_service, sku: "ERP-ENT-100") do |v|
  v.variant_name = "100 Users"
  v.variant_type = "service"
  v.price_override = 0
end
SellableVariant.find_or_create_by!(sellable: erp_service, sku: "ERP-ENT-500") do |v|
  v.variant_name = "500 Users"
  v.variant_type = "service"
  v.price_override = 400
end

# Service Config Specs (ERP)
ServiceConfigSpec.find_or_create_by!(service: erp_service, field_name: "user_count") do |s|
  s.data_type = "int"
  s.unit_price = 10
end
ServiceConfigSpec.find_or_create_by!(service: erp_service, field_name: "storage_gb") do |s|
  s.data_type = "int"
  s.unit_price = 5
end
ServiceConfigSpec.find_or_create_by!(service: erp_service, field_name: "priority_support") do |s|
  s.data_type = "bool"
  s.unit_price = 100
end

puts "✅ Seed data loaded successfully!"
puts "   - #{Brand.count} brands"
puts "   - #{Category.count} categories"
puts "   - #{Product.count} products"
puts "   - #{Service.count} services"
