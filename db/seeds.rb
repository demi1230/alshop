# Seeds файл - 10 жишээ өгөгдөл
# rails db:seed гэж ажиллуулна

puts "Creating users..."

# Admin user
admin = User.find_or_create_by!(email: 'admin@alshop.com') do |user|
  user.password = 'password123'
  user.password_confirmation = 'password123'
  user.role = 'admin'
end
puts "✓ Admin created: #{admin.email} (password: password123)"

# Customer user
customer = User.find_or_create_by!(email: 'customer@example.com') do |user|
  user.password = 'password123'
  user.password_confirmation = 'password123'
  user.role = 'customer'
end
puts "✓ Customer created: #{customer.email} (password: password123)"

# Staff user
staff = User.find_or_create_by!(email: 'staff@alshop.com') do |user|
  user.password = 'password123'
  user.password_confirmation = 'password123'
  user.role = 'staff'
end
puts "✓ Staff created: #{staff.email} (password: password123)"

puts "\n" + "="*50
puts "Creating hierarchical categories..."
puts "="*50

# Clear existing categories if any (development only)
if Rails.env.development? && Category.any?
  puts "⚠️  Clearing existing categories..."
  Category.where(parent_id: nil).destroy_all rescue nil
end

# LEVEL 1: Root Categories
electronics = Category.find_or_create_by!(name: 'Электроник', parent: nil)
fashion = Category.find_or_create_by!(name: 'Хувцас', parent: nil)
home = Category.find_or_create_by!(name: 'Гэр ахуй', parent: nil)
sports = Category.find_or_create_by!(name: 'Спорт', parent: nil)
books = Category.find_or_create_by!(name: 'Ном', parent: nil)

puts "✓ Level 1: #{Category.roots.count} root categories"

# LEVEL 2: Sub-categories under Electronics
computers = Category.find_or_create_by!(name: 'Компьютер', parent: electronics)
mobile = Category.find_or_create_by!(name: 'Гар утас', parent: electronics)
audio = Category.find_or_create_by!(name: 'Аудио видео', parent: electronics)
gaming = Category.find_or_create_by!(name: 'Тоглоом', parent: electronics)

# LEVEL 2: Sub-categories under Fashion
mens_fashion = Category.find_or_create_by!(name: "Эрэгтэй", parent: fashion)
womens_fashion = Category.find_or_create_by!(name: "Эмэгтэй", parent: fashion)
accessories = Category.find_or_create_by!(name: 'Дагалдах хэрэгсэл', parent: fashion)

# LEVEL 2: Sub-categories under Home & Living
furniture = Category.find_or_create_by!(name: 'Тавилга', parent: home)
kitchen = Category.find_or_create_by!(name: 'Гал тогоо', parent: home)
garden = Category.find_or_create_by!(name: 'Цэцэрлэг', parent: home)

# LEVEL 2: Sub-categories under Sports
fitness = Category.find_or_create_by!(name: 'Фитнесс', parent: sports)
outdoor = Category.find_or_create_by!(name: 'Гадаа спорт', parent: sports)

# LEVEL 2: Sub-categories under Books
fiction = Category.find_or_create_by!(name: 'Уран зохиол', parent: books)
nonfiction = Category.find_or_create_by!(name: 'Уран бус зохиол', parent: books)

puts "✓ Level 2: #{Category.where.not(parent_id: nil).where(id: Category.roots.flat_map(&:children).map(&:id)).count} sub-categories"

# LEVEL 3: Sub-sub-categories under Computers
laptops = Category.find_or_create_by!(name: 'Лаптоп', parent: computers)
desktops = Category.find_or_create_by!(name: 'Компьютер', parent: computers)
peripherals = Category.find_or_create_by!(name: 'Дагалдах хэрэгсэл', parent: computers)

# LEVEL 3: Sub-sub-categories under Mobile Devices
smartphones = Category.find_or_create_by!(name: 'Смартфон', parent: mobile)
tablets = Category.find_or_create_by!(name: 'Таблет', parent: mobile)

# LEVEL 3: Sub-sub-categories under Audio & Video
headphones = Category.find_or_create_by!(name: 'Чихэвч', parent: audio)
speakers = Category.find_or_create_by!(name: 'Чанга яригч', parent: audio)

# LEVEL 3: Sub-sub-categories under Men's Fashion
mens_clothing = Category.find_or_create_by!(name: 'Хувцас', parent: mens_fashion)
mens_shoes = Category.find_or_create_by!(name: 'Гутал', parent: mens_fashion)

# LEVEL 3: Sub-sub-categories under Women's Fashion
womens_clothing = Category.find_or_create_by!(name: 'Хувцас', parent: womens_fashion)
womens_shoes = Category.find_or_create_by!(name: 'Гутал', parent: womens_fashion)

# LEVEL 3: Sub-sub-categories under Fitness
cardio = Category.find_or_create_by!(name: 'Кардио төхөөрөмж', parent: fitness)
weights = Category.find_or_create_by!(name: 'Жин өргөх', parent: fitness)

# Additional categories for new seed data
food = Category.find_or_create_by!(name: 'Хүнс', parent: nil)
sweets = Category.find_or_create_by!(name: 'Амттан', parent: food)
chocolate = Category.find_or_create_by!(name: 'Шоколад', parent: sweets)

outerwear_women = Category.find_or_create_by!(name: 'Гадуур хувцас', parent: womens_fashion)
tv_category = Category.find_or_create_by!(name: 'ТВ', parent: audio)
oled_tv = Category.find_or_create_by!(name: 'OLED', parent: tv_category)
kitchen_appliances = Category.find_or_create_by!(name: 'Гал тогооны бараа', parent: kitchen)
coffee_machine = Category.find_or_create_by!(name: 'Кофе машин', parent: kitchen_appliances)

software = Category.find_or_create_by!(name: 'Програм хангамж', parent: nil)
erp_cat = Category.find_or_create_by!(name: 'ERP', parent: software)
org_erp = Category.find_or_create_by!(name: 'Байгууллага', parent: erp_cat)
it_services = Category.find_or_create_by!(name: 'Үйлчилгээ', parent: software)
it_support = Category.find_or_create_by!(name: 'IT Дэмжлэг', parent: it_services)

puts "✓ Level 3: Deep categories created"
puts "✓ Total categories: #{Category.count}"

# Show hierarchy
puts "\nCategory Hierarchy:"
Category.roots.each do |root|
  puts "📁 #{root.name} (ID: #{root.id})"
  root.children.each do |child|
    puts "  ├─ #{child.name} (ID: #{child.id})"
    child.children.each do |grandchild|
      puts "     └─ #{grandchild.name} (ID: #{grandchild.id})"
    end
  end
end

# Create Brands
brands = {
  apple: Brand.find_or_create_by!(name: 'Apple'),
  samsung: Brand.find_or_create_by!(name: 'Samsung'),
  sony: Brand.find_or_create_by!(name: 'Sony'),
  nike: Brand.find_or_create_by!(name: 'Nike'),
  adidas: Brand.find_or_create_by!(name: 'Adidas'),
  dell: Brand.find_or_create_by!(name: 'Dell'),
  hp: Brand.find_or_create_by!(name: 'HP'),
  penguin: Brand.find_or_create_by!(name: 'Penguin Books'),
  gobi: Brand.find_or_create_by!(name: 'Gobi Cashmere'),
  godiva: Brand.find_or_create_by!(name: 'Godiva'),
  delonghi: Brand.find_or_create_by!(name: 'DeLonghi')
}
puts "✓ Created #{brands.size} brands"

puts "\n" + "="*50
puts "Creating products in nested categories..."
puts "="*50

# Sample products data - MUST belong to LEAF categories (deepest level)
products_data = [
  # Electronics > Computers > Laptops
  { name: 'MacBook Pro 16"', price: 2499.99, category_obj: laptops, brand: :apple, active: true },
  { name: 'Dell XPS 15', price: 1899.99, category_obj: laptops, brand: :dell, active: true },
  { name: 'HP Spectre x360', price: 1599.99, category_obj: laptops, brand: :hp, active: true },
  
  # Electronics > Computers > Desktops
  { name: 'iMac 27"', price: 1999.99, category_obj: desktops, brand: :apple, active: true },
  { name: 'Dell OptiPlex компьютер', price: 899.99, category_obj: desktops, brand: :dell, active: true },
  
  # Electronics > Computers > Peripherals
  { name: 'Magic Mouse', price: 79.99, category_obj: peripherals, brand: :apple, active: true },
  { name: 'Утасгүй гар', price: 49.99, category_obj: peripherals, brand: :dell, active: false },
  
  # Electronics > Mobile Devices > Smartphones
  { name: 'iPhone 14', price: 999.99, category_obj: smartphones, brand: :apple, active: true },
  { name: 'Samsung Galaxy S24', price: 899.99, category_obj: smartphones, brand: :samsung, active: true },
  
  # Electronics > Mobile Devices > Tablets
  { name: 'iPad Air', price: 599.99, category_obj: tablets, brand: :apple, active: true },
  { name: 'Samsung Galaxy Tab', price: 449.99, category_obj: tablets, brand: :samsung, active: true },
  
  # Electronics > Audio & Video > Headphones
  { name: 'Sony WH-1000XM5 чихэвч', price: 399.99, category_obj: headphones, brand: :sony, active: true },
  { name: 'AirPods Pro', price: 249.99, category_obj: headphones, brand: :apple, active: true },
  
  # Electronics > Audio & Video > Speakers
  { name: 'Sony Bluetooth чанга яригч', price: 129.99, category_obj: speakers, brand: :sony, active: true },
  
  # Fashion > Men's Fashion > Shoes
  { name: 'Nike Air Max 90', price: 129.99, category_obj: mens_shoes, brand: :nike, active: true },
  { name: 'Adidas Ultraboost', price: 179.99, category_obj: mens_shoes, brand: :adidas, active: true },
  
  # Fashion > Men's Fashion > Clothing
  { name: 'Nike Dri-FIT цамц', price: 29.99, category_obj: mens_clothing, brand: :nike, active: true },
  
  # Fashion > Women's Fashion > Shoes
  { name: 'Nike Air Force 1', price: 119.99, category_obj: womens_shoes, brand: :nike, active: true },
  
  # Sports > Fitness > Cardio Equipment
  { name: 'Гүйлтийн зам', price: 899.99, category_obj: cardio, brand: nil, active: true },
  
  # Sports > Fitness > Weights
  { name: 'Ганга 20кг', price: 89.99, category_obj: weights, brand: nil, active: true },
  
  # Books > Fiction
  { name: '1984 - Жорж Оруэлл', price: 14.99, category_obj: fiction, brand: :penguin, active: true },
  { name: 'Шагайт шувуу алахыг - Харпер Ли', price: 12.99, category_obj: fiction, brand: :penguin, active: true },
  
  # Books > Non-Fiction
  { name: 'Sapiens - Хүн төрөлхтний товч түүх', price: 18.99, category_obj: nonfiction, brand: :penguin, active: true },
]

created_count = 0
products_data.each do |data|
  # Check if product already exists by sellable name
  sellable = Sellable.find_by(name: data[:name], sellable_type: 'Product')
  
  unless sellable
    sellable = Sellable.create!(
      name: data[:name],
      base_price: data[:price],
      sellable_type: 'Product',
      is_active: data[:active]
    )
    
    Product.create!(
      sellable: sellable,
      category: data[:category_obj],
      brand: data[:brand] ? brands[data[:brand]] : nil
    )
    
    created_count += 1
  end
end

puts "✓ Created #{created_count} new products (#{products_data.size} total in seed data)"

# -----------------------------
# CREATE NEW 10 PRODUCTS/SERVICES
# -----------------------------
puts "\n" + "="*50
puts "Creating 10 new products/services..."
puts "="*50

new_items_created = 0

# 1. Оёмол пончо (Product)
poncho_sellable = Sellable.find_or_create_by!(name: "Оёмол пончо") do |s|
  s.sellable_type = "Product"
  s.base_price = 1198000
  s.is_active = true
  s.description = "Төрөл бүрийн биеийн хэлбэрт тохирох өмсгөл суулт, өнгөний сонголт бүхий хөнгөн бөгөөд дулаан 100% ноолууран Пончо нь таны өдөр тутам, үдшийн, ажил хэргийн алинд ч тохирох тансаг байдал, үнэ цэний илэрхийлэмж болж чадна."
end

unless Product.exists?(sellable: poncho_sellable)
  Product.create!(
    sellable: poncho_sellable,
    category: outerwear_women,
    brand: brands[:gobi]
  )
  
  # Variants
  variants_data = [
    { name: "S / Хар", attrs: { size: "S", color: "Хар" }, stock: 1 },
    { name: "M / Ногоон", attrs: { size: "M", color: "Ногоон" }, stock: 2 },
    { name: "L / Цагаан", attrs: { size: "L", color: "Цагаан" }, stock: 4 },
    { name: "XL / Ногоон", attrs: { size: "XL", color: "Ногоон" }, stock: 3 },
    { name: "XL / Хар", attrs: { size: "XL", color: "Хар" }, stock: 4 }
  ]
  
  variants_data.each do |v|
    sku = "PONCHO-#{v[:attrs][:size]}-#{v[:attrs][:color][0..2].upcase}"
    variant = SellableVariant.find_or_create_by!(
      sellable: poncho_sellable,
      sku: sku
    ) do |sv|
      sv.variant_name = v[:name]
      sv.attributes = v[:attrs]
      sv.is_active = true
    end
    
    Inventory.find_or_create_by!(sellable_variant: variant) do |inv|
      inv.quantity = v[:stock]
    end
  end
  
  # Pricing rule: Ногоон өнгө + S/M/L → 10% discount
  PricingRule.create!(
    sellable: poncho_sellable,
    channel: 'public',
    discount_type: 'percentage',
    value: 10.0,
    priority: 10,
    valid_from: Time.current,
    valid_to: 1.year.from_now
  )
  
  new_items_created += 1
end

# 2. Тансаг шоколадны цуглуулга (Product)
chocolate_sellable = Sellable.find_or_create_by!(name: "Тансаг шоколадны цуглуулга") do |s|
  s.sellable_type = "Product"
  s.base_price = 300800
  s.is_active = true
  s.description = "Тансаг шоколадны цуглуулга Гоёмсог материалаар бүрсэн хайрцагтай, бэлэглэхэд хамгийн тохиромжтой цуглуулга. Энэхүү цуглуулгад маш олон төрлийн шоколад, трюфль багтсан байдаг."
end

unless Product.exists?(sellable: chocolate_sellable)
  Product.create!(
    sellable: chocolate_sellable,
    category: chocolate,
    brand: brands[:godiva]
  )
  
  # Variants by quantity
  [
    { name: "12ш", price: 300800, stock: 15 },
    { name: "30ш", price: 500800, stock: 10 },
    { name: "59ш", price: 1250800, stock: 4 }
  ].each do |v|
    variant = SellableVariant.create!(
      sellable: chocolate_sellable,
      variant_name: v[:name],
      sku: "GODIVA-#{v[:name]}",
      price_override: v[:price],
      attributes: { count: v[:name] },
      is_active: true
    )
    
    Inventory.create!(sellable_variant: variant, quantity: v[:stock])
  end
  
  # Pricing rule: 59ш variant → 20% discount
  PricingRule.create!(
    sellable: chocolate_sellable,
    channel: 'public',
    discount_type: 'percentage',
    value: 20.0,
    priority: 10,
    valid_from: Time.current,
    valid_to: 1.year.from_now
  )
  
  new_items_created += 1
end

# 3. iPhone 15 Pro (Product)
iphone15_sellable = Sellable.find_or_create_by!(name: "iPhone 15 Pro") do |s|
  s.sellable_type = "Product"
  s.base_price = 5200000
  s.is_active = true
  s.description = "Apple iPhone 15 Pro with A17 Pro chip and advanced camera system"
end

unless Product.exists?(sellable: iphone15_sellable)
  Product.create!(
    sellable: iphone15_sellable,
    category: smartphones,
    brand: brands[:apple]
  )
  
  [
    { name: "128GB / Хар", attrs: { storage: "128GB", color: "Хар" }, stock: 5 },
    { name: "256GB / Цэнхэр", attrs: { storage: "256GB", color: "Цэнхэр" }, stock: 3 },
    { name: "512GB / Титан", attrs: { storage: "512GB", color: "Титан" }, stock: 2 }
  ].each do |v|
    variant = SellableVariant.create!(
      sellable: iphone15_sellable,
      variant_name: v[:name],
      sku: "IPHONE15PRO-#{v[:attrs][:storage]}-#{v[:attrs][:color][0..2].upcase}",
      attributes: v[:attrs],
      is_active: true
    )
    
    Inventory.create!(sellable_variant: variant, quantity: v[:stock])
  end
  
  # Public channel → 5% discount
  PricingRule.create!(
    sellable: iphone15_sellable,
    channel: 'public',
    discount_type: 'percentage',
    value: 5.0,
    priority: 10,
    valid_from: Time.current,
    valid_to: 1.year.from_now
  )
  
  new_items_created += 1
end

# 4. MacBook Air M3 (Product)
mbair_sellable = Sellable.find_or_create_by!(name: "MacBook Air M3") do |s|
  s.sellable_type = "Product"
  s.base_price = 6800000
  s.is_active = true
  s.description = "MacBook Air with M3 chip - powerful and portable"
end

unless Product.exists?(sellable: mbair_sellable)
  Product.create!(
    sellable: mbair_sellable,
    category: laptops,
    brand: brands[:apple]
  )
  
  [
    { name: "512GB SSD", attrs: { storage: "512GB SSD" }, stock: 4 },
    { name: "1TB SSD", attrs: { storage: "1TB SSD" }, stock: 2 }
  ].each do |v|
    variant = SellableVariant.create!(
      sellable: mbair_sellable,
      variant_name: v[:name],
      sku: "MBA-M3-#{v[:attrs][:storage].gsub(' ', '-')}",
      attributes: v[:attrs],
      is_active: true
    )
    
    Inventory.create!(sellable_variant: variant, quantity: v[:stock])
  end
  
  # Yearly promo → 300,000₮ fixed discount
  PricingRule.create!(
    sellable: mbair_sellable,
    channel: 'promo',
    discount_type: 'fixed',
    value: 300000,
    priority: 15,
    valid_from: Time.current,
    valid_to: 1.year.from_now,
    promo_code: 'YEARLY2026'
  )
  
  new_items_created += 1
end

# 5. Sony WH-1000XM5 (Product)
sony_headphone_sellable = Sellable.find_or_create_by!(name: "Sony WH-1000XM5") do |s|
  s.sellable_type = "Product"
  s.base_price = 1450000
  s.is_active = true
  s.description = "Premium noise cancelling wireless headphones"
end

unless Product.exists?(sellable: sony_headphone_sellable)
  Product.create!(
    sellable: sony_headphone_sellable,
    category: headphones,
    brand: brands[:sony]
  )
  
  [
    { name: "Хар", attrs: { color: "Хар" }, stock: 6 },
    { name: "Мөнгөлөг", attrs: { color: "Мөнгөлөг" }, stock: 4 }
  ].each do |v|
    variant = SellableVariant.create!(
      sellable: sony_headphone_sellable,
      variant_name: v[:name],
      sku: "SONY-WH1000XM5-#{v[:attrs][:color][0..2].upcase}",
      attributes: v[:attrs],
      is_active: true
    )
    
    Inventory.create!(sellable_variant: variant, quantity: v[:stock])
  end
  
  new_items_created += 1
end

# 6. Sony Bravia OLED 55" (Product)
sony_tv_sellable = Sellable.find_or_create_by!(name: "Sony Bravia OLED 55\"") do |s|
  s.sellable_type = "Product"
  s.base_price = 7900000
  s.is_active = true
  s.description = "Premium OLED TV with 4K resolution and exceptional picture quality"
end

unless Product.exists?(sellable: sony_tv_sellable)
  Product.create!(
    sellable: sony_tv_sellable,
    category: oled_tv,
    brand: brands[:sony]
  )
  
  variant = SellableVariant.create!(
    sellable: sony_tv_sellable,
    variant_name: "55 inch",
    sku: "SONY-BRAVIA-OLED-55",
    attributes: { size: "55\"", resolution: "4K", panel: "OLED" },
    is_active: true
  )
  
  Inventory.create!(sellable_variant: variant, quantity: 2)
  
  # Public channel → 8% discount
  PricingRule.create!(
    sellable: sony_tv_sellable,
    channel: 'public',
    discount_type: 'percentage',
    value: 8.0,
    priority: 10,
    valid_from: Time.current,
    valid_to: 1.year.from_now
  )
  
  new_items_created += 1
end

# 7. Эрэгтэй спорт пүүз (Product)
nike_shoes_sellable = Sellable.find_or_create_by!(name: "Эрэгтэй спорт пүүз") do |s|
  s.sellable_type = "Product"
  s.base_price = 420000
  s.is_active = true
  s.description = "Эрэгтэй хөнгөн спорт гутал - тав тухтай, чанартай"
end

unless Product.exists?(sellable: nike_shoes_sellable)
  Product.create!(
    sellable: nike_shoes_sellable,
    category: mens_shoes,
    brand: brands[:nike]
  )
  
  [
    { name: "42 / Хар", attrs: { size: "42", color: "Хар" }, stock: 5 },
    { name: "43 / Цагаан", attrs: { size: "43", color: "Цагаан" }, stock: 3 }
  ].each do |v|
    variant = SellableVariant.create!(
      sellable: nike_shoes_sellable,
      variant_name: v[:name],
      sku: "NIKE-SPORT-#{v[:attrs][:size]}-#{v[:attrs][:color][0..2].upcase}",
      attributes: v[:attrs],
      is_active: true
    )
    
    Inventory.create!(sellable_variant: variant, quantity: v[:stock])
  end
  
  # 5% discount
  PricingRule.create!(
    sellable: nike_shoes_sellable,
    channel: 'public',
    discount_type: 'percentage',
    value: 5.0,
    priority: 10,
    valid_from: Time.current,
    valid_to: 1.year.from_now
  )
  
  new_items_created += 1
end

# 8. Кофе машин (Product)
coffee_sellable = Sellable.find_or_create_by!(name: "Кофе машин") do |s|
  s.sellable_type = "Product"
  s.base_price = 2300000
  s.is_active = true
  s.description = "DeLonghi автомат кофе машин - гэртээ кофе шопын амтыг"
end

unless Product.exists?(sellable: coffee_sellable)
  Product.create!(
    sellable: coffee_sellable,
    category: coffee_machine,
    brand: brands[:delonghi]
  )
  
  variant = SellableVariant.create!(
    sellable: coffee_sellable,
    variant_name: "Хар",
    sku: "DELONGHI-COFFEE-BLACK",
    attributes: { color: "Хар", pressure: "15 bar" },
    is_active: true
  )
  
  Inventory.create!(sellable_variant: variant, quantity: 2)
  
  # Promo code: COFFEE10 → 10% discount
  PricingRule.create!(
    sellable: coffee_sellable,
    channel: 'promo',
    discount_type: 'percentage',
    value: 10.0,
    priority: 15,
    valid_from: Time.current,
    valid_to: 1.year.from_now,
    promo_code: 'COFFEE10'
  )
  
  new_items_created += 1
end

# 9. Байгууллагын ERP систем (Service)
erp_system_sellable = Sellable.find_or_create_by!(name: "Байгууллагын ERP систем") do |s|
  s.sellable_type = "Service"
  s.base_price = 3500000
  s.is_active = true
  s.description = "Байгууллагын бүрэн ERP систем - Accounting, Inventory, HR модультай"
end

unless Service.exists?(sellable: erp_system_sellable)
  Service.create!(
    sellable: erp_system_sellable,
    category: org_erp,
    service_type: "subscription",
    requires_schedule: false
  )
  
  erp_service = Service.find_by(sellable: erp_system_sellable)
  
  # Service config specs
  ServiceConfigSpec.create!(
    service: erp_service,
    field_name: "User count",
    data_type: "int",
    unit_price: 50000
  )
  
  ServiceConfigSpec.create!(
    service: erp_service,
    field_name: "Extra module",
    data_type: "bool",
    unit_price: 300000
  )
  
  # Public channel → 10% discount
  PricingRule.create!(
    sellable: erp_system_sellable,
    channel: 'public',
    discount_type: 'percentage',
    value: 10.0,
    priority: 10,
    valid_from: Time.current,
    valid_to: 1.year.from_now
  )
  
  new_items_created += 1
end

# 10. ERP Customization & Support (Service)
erp_support_sellable = Sellable.find_or_create_by!(name: "ERP Customization & Support") do |s|
  s.sellable_type = "Service"
  s.base_price = 120000
  s.is_active = true
  s.description = "ERP системийн тусгай өөрчлөлт болон дэмжлэг үйлчилгээ - цагаар"
end

unless Service.exists?(sellable: erp_support_sellable)
  Service.create!(
    sellable: erp_support_sellable,
    category: it_support,
    service_type: "hourly",
    requires_schedule: true
  )
  
  erp_support_service = Service.find_by(sellable: erp_support_sellable)
  
  # Service config
  ServiceConfigSpec.create!(
    service: erp_support_service,
    field_name: "Support level",
    data_type: "string",
    unit_price: 0
  )
  
  # Service variants with different pricing
  SellableVariant.create!(
    sellable: erp_support_sellable,
    variant_name: "Standard",
    sku: "ERP-SUPPORT-STD",
    price_override: 120000,
    attributes: { level: "Standard" },
    is_active: true
  )
  
  SellableVariant.create!(
    sellable: erp_support_sellable,
    variant_name: "Premium",
    sku: "ERP-SUPPORT-PREM",
    price_override: 180000,
    attributes: { level: "Premium" },
    is_active: true
  )
  
  # Public channel → 15% discount
  PricingRule.create!(
    sellable: erp_support_sellable,
    channel: 'public',
    discount_type: 'percentage',
    value: 15.0,
    priority: 10,
    valid_from: Time.current,
    valid_to: 1.year.from_now
  )
  
  new_items_created += 1
end

puts "✓ Created #{new_items_created} new products/services"

# -----------------------------
# CREATE SERVICES
# -----------------------------
puts "\n" + "="*50
puts "Creating services..."
puts "="*50

# Find service categories
automotive_services = Category.find_by(name: "Automotive Services")
erp_services = Category.find_by(name: "ERP Services")

services_created = 0

# Toyota Full Service
if automotive_services
  toyota_service = Sellable.find_or_create_by!(name: "Toyota Full Service Package") do |s|
    s.sellable_type = "Service"
    s.base_price = 150
    s.is_active = true
    s.description = "Comprehensive vehicle maintenance by Toyota Mongolia certified mechanics"
  end
  
  unless Service.exists?(sellable: toyota_service)
    Service.create!(
      sellable: toyota_service,
      category: automotive_services,
      service_type: "fixed",
      requires_schedule: true
    )
    services_created += 1
  end
end

# ERP Enterprise Package
if erp_services
  erp_service = Sellable.find_or_create_by!(name: "Xerox ERP Enterprise Package") do |s|
    s.sellable_type = "Service"
    s.base_price = 5000
    s.is_active = true
    s.description = "Complete enterprise resource planning solution by Xerox Mongolia"
  end
  
  unless Service.exists?(sellable: erp_service)
    Service.create!(
      sellable: erp_service,
      category: erp_services,
      service_type: "subscription",
      requires_schedule: false
    )
    services_created += 1
  end
end

puts "✓ Created #{services_created} new services"

# -----------------------------
# CREATE PRICING RULES
# -----------------------------
puts "\n" + "="*50
puts "Creating pricing rules..."
puts "="*50

pricing_rules_created = 0

# Get some sellables for pricing rules
macbook = Sellable.find_by(name: "MacBook Pro 16\"")
dell_xps = Sellable.find_by(name: "Dell XPS 15")
toyota_service = Sellable.find_by(name: "Toyota Full Service Package")

# 1. Public discount - 10% off on Dell XPS (active now)
if dell_xps
  PricingRule.find_or_create_by!(
    sellable: dell_xps,
    channel: 'public',
    discount_type: 'percentage'
  ) do |pr|
    pr.value = 10.0
    pr.priority = 10
    pr.valid_from = 1.month.ago
    pr.valid_to = 1.month.from_now
  end
  pricing_rules_created += 1
end

# 2. Future promotion - $200 fixed discount on MacBook
if macbook
  PricingRule.find_or_create_by!(
    sellable: macbook,
    channel: 'public',
    discount_type: 'fixed'
  ) do |pr|
    pr.value = 200.0
    pr.priority = 15
    pr.valid_from = 1.week.from_now
    pr.valid_to = 2.months.from_now
  end
  pricing_rules_created += 1
end

# 3. Promo code discount - 15% with code "WELCOME15"
if macbook
  PricingRule.find_or_create_by!(
    sellable: macbook,
    channel: 'promo',
    discount_type: 'percentage',
    promo_code: 'WELCOME15'
  ) do |pr|
    pr.value = 15.0
    pr.priority = 20
    pr.valid_from = 1.week.ago
    pr.valid_to = 3.months.from_now
  end
  pricing_rules_created += 1
end

# 4. Service discount - $20 off Toyota Service
if toyota_service
  PricingRule.find_or_create_by!(
    sellable: toyota_service,
    channel: 'public',
    discount_type: 'fixed'
  ) do |pr|
    pr.value = 20.0
    pr.priority = 10
    pr.valid_from = Time.current
    pr.valid_to = 6.months.from_now
  end
  pricing_rules_created += 1
end

puts "✓ Created #{pricing_rules_created} new pricing rules"

puts "\n" + "="*50
puts "Seed data created successfully!"
puts "="*50
puts "\nLogin credentials:"
puts "  Admin:    admin@alshop.com / password123"
puts "  Customer: customer@example.com / password123"
puts "  Staff:    staff@alshop.com / password123"
puts "\nProducts: #{Product.count} total (#{Product.active.count} active)"
puts "Services: #{Service.count} total"
puts "Pricing Rules: #{PricingRule.count} total (#{PricingRule.active.count} active)"
puts "Categories: #{Category.count}"
puts "Brands: #{Brand.count}"
