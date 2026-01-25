# Mongolian Example Data Seeds
# Энэхүү файл нь монгол өгөгдлийн жишээ юм

puts "🧹 Cleaning up existing data..."
# Эхлээд хуучин өгөгдлийг арилгах (хэрэв шинээр эхлэх бол)
# Inventory.destroy_all
# SellableVariant.destroy_all
# PricingRule.destroy_all
# Specification.destroy_all
# Product.destroy_all
# Service.destroy_all
# Sellable.destroy_all
# CategoryAttribute.destroy_all
# Category.destroy_all
# Brand.destroy_all

puts "📦 Creating Categories..."

# 1️⃣ Хувцас
huvtsas = Category.create!(name: "Хувцас", description: "Эрэгтэй, эмэгтэй хувцас")
huvtsas_emegtei = Category.create!(name: "Эмэгтэй", parent: huvtsas)
huvtsas_gaduut = Category.create!(name: "Гадуур хувцас", parent: huvtsas_emegtei)

# 2️⃣ Хүнс
huns = Category.create!(name: "Хүнс", description: "Хоол, амттан")
huns_amttan = Category.create!(name: "Амттан", parent: huns)
huns_shokolad = Category.create!(name: "Шоколад", parent: huns_amttan)

# 3️⃣ Цахилгаан бараа
tsahilgaan = Category.create!(name: "Цахилгаан бараа", description: "Электроник бараа")
tsahilgaan_gar_utas = Category.create!(name: "Гар утас", parent: tsahilgaan)
tsahilgaan_chihevch = Category.create!(name: "Чихэвч", parent: tsahilgaan)

# 4️⃣ Программ хангамж
program = Category.create!(name: "Программ хангамж", description: "Програм хангамж")
program_baigiullagiin = Category.create!(name: "Байгууллагын систем", parent: program)
program_erp = Category.create!(name: "ERP", parent: program_baigiullagiin)

puts "✅ Created #{Category.count} categories"

puts "🏷️ Creating Brands..."

gobi = Brand.create!(name: "Gobi Cashmere", website_url: "gobi.mn")
godiva = Brand.create!(name: "Godiva", website_url: "godiva.com")
apple = Brand.create!(name: "Apple", website_url: "apple.com")
sony = Brand.create!(name: "Sony", website_url: "sony.com")

puts "✅ Created #{Brand.count} brands"

puts "🧥 Creating Product #1 - Оёмол пончо..."

# Sellable #1
poncho_sellable = Sellable.create!(
  name: "Оёмол пончо",
  sellable_type: "Product",
  base_price: 1_198_000,
  description: "100% ноолууран, сул загвартай, дулаан",
  is_active: true
)

# Product
poncho_product = Product.create!(
  sellable: poncho_sellable,
  category: huvtsas_gaduut,
  brand: gobi,
  sku_base: "PON"
)

# Category Attributes for this category
material_attr = CategoryAttribute.find_or_create_by!(
  category: huvtsas_gaduut,
  name: "Материал",
  is_required: true
)
zagvar_attr = CategoryAttribute.find_or_create_by!(
  category: huvtsas_gaduut,
  name: "Загвар",
  is_required: false
)
huis_attr = CategoryAttribute.find_or_create_by!(
  category: huvtsas_gaduut,
  name: "Хүйс",
  is_required: false
)

# Specifications
Specification.create!(sellable: poncho_sellable, category_attribute: material_attr, value: "Ноолуур")
Specification.create!(sellable: poncho_sellable, category_attribute: zagvar_attr, value: "Сул")
Specification.create!(sellable: poncho_sellable, category_attribute: huis_attr, value: "Эмэгтэй")

# Variants
variant_pon_blk_s = SellableVariant.create!(
  sellable: poncho_sellable,
  variant_name: "Хар / S",
  sku: "PON-BLK-S",
  attributes: { color: "Хар", size: "S" }
)
Inventory.create!(sellable_variant: variant_pon_blk_s, quantity: 1)

variant_pon_grn_m = SellableVariant.create!(
  sellable: poncho_sellable,
  variant_name: "Ногоон / M",
  sku: "PON-GRN-M",
  attributes: { color: "Ногоон", size: "M" }
)
Inventory.create!(sellable_variant: variant_pon_grn_m, quantity: 2)

variant_pon_wht_l = SellableVariant.create!(
  sellable: poncho_sellable,
  variant_name: "Цагаан / L",
  sku: "PON-WHT-L",
  attributes: { color: "Цагаан", size: "L" }
)
Inventory.create!(sellable_variant: variant_pon_wht_l, quantity: 4)

variant_pon_grn_xl = SellableVariant.create!(
  sellable: poncho_sellable,
  variant_name: "Ногоон / XL",
  sku: "PON-GRN-XL",
  attributes: { color: "Ногоон", size: "XL" }
)
Inventory.create!(sellable_variant: variant_pon_grn_xl, quantity: 3)

variant_pon_blk_xl = SellableVariant.create!(
  sellable: poncho_sellable,
  variant_name: "Хар / XL",
  sku: "PON-BLK-XL",
  attributes: { color: "Хар", size: "XL" }
)
Inventory.create!(sellable_variant: variant_pon_blk_xl, quantity: 4)

# Pricing Rule: 10% хямдрал ногоон өнгөнд (S, M, L)
[variant_pon_grn_m].each do |variant|
  PricingRule.create!(
    sellable_variant: variant,
    channel: "public",
    discount_type: "percentage",
    value: 10.0,
    priority: 10
  )
end

puts "✅ Created Poncho with #{poncho_sellable.sellable_variants.count} variants"

puts "🍫 Creating Product #2 - Тансаг шоколадны цуглуулга..."

# Sellable #2
chocolate_sellable = Sellable.create!(
  name: "Тансаг шоколадны цуглуулга",
  sellable_type: "Product",
  base_price: 1_250_800,
  description: "Бельгийн шоколад, өндөр чанартай",
  is_active: true
)

chocolate_product = Product.create!(
  sellable: chocolate_sellable,
  category: huns_shokolad,
  brand: godiva
)

# Specs
kakao_attr = CategoryAttribute.find_or_create_by!(category: huns_shokolad, name: "Какао хувь")
savlagaa_attr = CategoryAttribute.find_or_create_by!(category: huns_shokolad, name: "Савлагаа")

Specification.create!(sellable: chocolate_sellable, category_attribute: kakao_attr, value: "56%")
Specification.create!(sellable: chocolate_sellable, category_attribute: savlagaa_attr, value: "Бэлгийн хайрцаг")

# Variants
variant_god_59 = SellableVariant.create!(
  sellable: chocolate_sellable,
  variant_name: "59 ширхэг",
  sku: "GOD-59",
  price_override: 1_250_800
)
Inventory.create!(sellable_variant: variant_god_59, quantity: 4)

variant_god_30 = SellableVariant.create!(
  sellable: chocolate_sellable,
  variant_name: "30 ширхэг",
  sku: "GOD-30",
  price_override: 500_800
)
Inventory.create!(sellable_variant: variant_god_30, quantity: 10)

variant_god_12 = SellableVariant.create!(
  sellable: chocolate_sellable,
  variant_name: "12 ширхэг",
  sku: "GOD-12",
  price_override: 300_800
)
Inventory.create!(sellable_variant: variant_god_12, quantity: 15)

# Pricing: 20% off on GOD-59
PricingRule.create!(
  sellable_variant: variant_god_59,
  channel: "public",
  discount_type: "percentage",
  value: 20.0,
  priority: 10
)

puts "✅ Created Chocolate with #{chocolate_sellable.sellable_variants.count} variants"

puts "📱 Creating Product #3 - iPhone 15..."

iphone_sellable = Sellable.create!(
  name: "iPhone 15",
  sellable_type: "Product",
  base_price: 4_200_000,
  description: "A17 чип, iOS, дэлхийн шилдэг гар утас",
  is_active: true
)

iphone_product = Product.create!(
  sellable: iphone_sellable,
  category: tsahilgaan_gar_utas,
  brand: apple
)

# Specs
cpu_attr = CategoryAttribute.find_or_create_by!(category: tsahilgaan_gar_utas, name: "CPU")
os_attr = CategoryAttribute.find_or_create_by!(category: tsahilgaan_gar_utas, name: "OS")

Specification.create!(sellable: iphone_sellable, category_attribute: cpu_attr, value: "A17")
Specification.create!(sellable: iphone_sellable, category_attribute: os_attr, value: "iOS")

# Variants
variant_ip15_blk = SellableVariant.create!(
  sellable: iphone_sellable,
  variant_name: "Хар / 128GB",
  sku: "IP15-BLK-128",
  attributes: { color: "Хар", storage: "128GB" }
)
Inventory.create!(sellable_variant: variant_ip15_blk, quantity: 10)

variant_ip15_blu = SellableVariant.create!(
  sellable: iphone_sellable,
  variant_name: "Цэнхэр / 256GB",
  sku: "IP15-BLU-256",
  price_override: 4_600_000,
  attributes: { color: "Цэнхэр", storage: "256GB" }
)
Inventory.create!(sellable_variant: variant_ip15_blu, quantity: 5)

puts "✅ Created iPhone with #{iphone_sellable.sellable_variants.count} variants"

puts "🎧 Creating Product #4 - Sony WH-1000XM5..."

sony_sellable = Sellable.create!(
  name: "Sony WH-1000XM5",
  sellable_type: "Product",
  base_price: 1_450_000,
  description: "Дуу намсгагчтай, утасгүй чихэвч",
  is_active: true
)

sony_product = Product.create!(
  sellable: sony_sellable,
  category: tsahilgaan_chihevch,
  brand: sony
)

# No variants needed - just base product
Inventory.create!(
  sellable_variant: SellableVariant.create!(
    sellable: sony_sellable,
    variant_name: "Standard",
    sku: "SONY-WH1000XM5"
  ),
  quantity: 20
)

puts "✅ Created Sony headphones"

puts "🏢 Creating Service #5 - ERP System..."

erp_sellable = Sellable.create!(
  name: "ERP System",
  sellable_type: "Service",
  base_price: 500_000,
  description: "Байгууллагын нөөц бүтээгдэхүүн удирдлагын систем",
  is_active: true
)

erp_service = Service.create!(
  sellable: erp_sellable,
  category: program_erp,
  service_type: "subscription",
  requires_schedule: false,
  terms: "Сар бүр төлбөр, 12 сарын гэрээ"
)

# Service Config Specs
ServiceConfigSpec.create!(
  service: erp_service,
  field_name: "user_count",
  data_type: "int",
  description: "Хэрэглэгчийн тоо",
  unit_price: 50_000
)

ServiceConfigSpec.create!(
  service: erp_service,
  field_name: "storage_gb",
  data_type: "int",
  description: "Хадгалах сангийн хэмжээ (GB)",
  unit_price: 10_000
)

ServiceConfigSpec.create!(
  service: erp_service,
  field_name: "support",
  data_type: "bool",
  description: "24/7 дэмжлэг",
  unit_price: 200_000
)

# Service Variants (packages)
SellableVariant.create!(
  sellable: erp_sellable,
  variant_name: "ERP 10 Users",
  price_override: 500_000,
  attributes: { users: 10, storage: 10, support: false }
)

SellableVariant.create!(
  sellable: erp_sellable,
  variant_name: "ERP 50 Users",
  price_override: 2_000_000,
  attributes: { users: 50, storage: 100, support: true }
)

SellableVariant.create!(
  sellable: erp_sellable,
  variant_name: "ERP Unlimited",
  price_override: 5_000_000,
  attributes: { users: -1, storage: 1000, support: true }
)

puts "✅ Created ERP service with #{erp_sellable.sellable_variants.count} packages"

puts ""
puts "🎉 DONE! Summary:"
puts "   Categories: #{Category.count}"
puts "   Brands: #{Brand.count}"
puts "   Sellables: #{Sellable.count}"
puts "   Products: #{Product.count}"
puts "   Services: #{Service.count}"
puts "   Variants: #{SellableVariant.count}"
puts "   Inventories: #{Inventory.count}"
puts "   Pricing Rules: #{PricingRule.count}"
puts "   Specifications: #{Specification.count}"
puts ""
puts "💡 To load this data, run:"
puts "   bin/rails runner db/seeds_mongolian_example.rb"
