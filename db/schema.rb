# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_01_27_052949) do
  create_table "brands", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.string "website_url"
  end

  create_table "cart_items", force: :cascade do |t|
    t.integer "cart_id", null: false
    t.json "configuration"
    t.datetime "created_at", null: false
    t.decimal "line_price_estimate", precision: 10, scale: 2
    t.integer "quantity", null: false
    t.integer "sellable_id", null: false
    t.integer "sellable_variant_id"
    t.datetime "updated_at", null: false
    t.index ["cart_id"], name: "index_cart_items_on_cart_id"
    t.index ["sellable_id"], name: "index_cart_items_on_sellable_id"
    t.index ["sellable_variant_id"], name: "index_cart_items_on_sellable_variant_id"
    t.check_constraint "quantity > 0", name: "cart_items_quantity_positive"
  end

  create_table "carts", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "expires_at"
    t.string "session_id"
    t.string "status", default: "active", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.index ["session_id"], name: "index_carts_on_session_id"
    t.index ["user_id", "status"], name: "index_carts_on_user_id_and_status", unique: true, where: "status = 'active' AND user_id IS NOT NULL"
    t.index ["user_id"], name: "index_carts_on_user_id"
  end

  create_table "categories", force: :cascade do |t|
    t.string "category_type", default: "both"
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name", null: false
    t.integer "parent_id"
    t.datetime "updated_at", null: false
    t.index ["category_type"], name: "index_categories_on_category_type"
    t.index ["parent_id"], name: "index_categories_on_parent_id"
  end

  create_table "category_attributes", force: :cascade do |t|
    t.integer "category_id", null: false
    t.datetime "created_at", null: false
    t.boolean "is_required", default: false, null: false
    t.string "name", null: false
    t.string "unit"
    t.datetime "updated_at", null: false
    t.index ["category_id"], name: "index_category_attributes_on_category_id"
  end

  create_table "companies", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "is_active", default: true, null: false
    t.string "name", null: false
    t.integer "parent_company_id"
    t.datetime "updated_at", null: false
    t.index ["parent_company_id"], name: "index_companies_on_parent_company_id"
  end

  create_table "inventories", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "quantity", default: 0, null: false
    t.integer "sellable_variant_id", null: false
    t.datetime "updated_at", null: false
    t.integer "warehouse_id"
    t.index ["sellable_variant_id", "warehouse_id"], name: "index_inventories_on_variant_and_warehouse", unique: true, where: "warehouse_id IS NOT NULL"
    t.index ["sellable_variant_id"], name: "index_inventories_on_variant_only", unique: true, where: "warehouse_id IS NULL"
    t.check_constraint "quantity >= 0", name: "inventories_quantity_non_negative"
  end

  create_table "order_items", force: :cascade do |t|
    t.json "config_snapshot"
    t.datetime "created_at", null: false
    t.decimal "line_total", precision: 10, scale: 2, null: false
    t.integer "order_id", null: false
    t.decimal "price_at_purchase", precision: 10, scale: 2, null: false
    t.integer "quantity", null: false
    t.integer "sellable_id", null: false
    t.integer "sellable_variant_id"
    t.datetime "updated_at", null: false
    t.index ["order_id"], name: "index_order_items_on_order_id"
    t.index ["sellable_id"], name: "index_order_items_on_sellable_id"
    t.index ["sellable_variant_id"], name: "index_order_items_on_sellable_variant_id"
    t.check_constraint "quantity > 0", name: "order_items_quantity_positive"
  end

  create_table "orders", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.json "metadata"
    t.string "status", default: "pending", null: false
    t.decimal "total_price", precision: 10, scale: 2, null: false
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.index ["status"], name: "index_orders_on_status"
    t.index ["user_id"], name: "index_orders_on_user_id"
  end

  create_table "pricing_rules", force: :cascade do |t|
    t.string "channel", null: false
    t.integer "company_id"
    t.datetime "created_at", null: false
    t.string "discount_type", null: false
    t.integer "priority", default: 0, null: false
    t.string "promo_code"
    t.integer "sellable_id"
    t.integer "sellable_variant_id"
    t.bigint "sub_company_id"
    t.datetime "updated_at", null: false
    t.datetime "valid_from"
    t.datetime "valid_to"
    t.decimal "value", precision: 10, scale: 2, null: false
    t.index ["channel"], name: "index_pricing_rules_on_channel"
    t.index ["company_id"], name: "index_pricing_rules_on_company_id"
    t.index ["promo_code"], name: "index_pricing_rules_on_promo_code", where: "promo_code IS NOT NULL"
    t.index ["sellable_id", "priority"], name: "index_pricing_rules_on_sellable_id_and_priority"
    t.index ["sellable_id"], name: "index_pricing_rules_on_sellable_id"
    t.index ["sellable_variant_id", "priority"], name: "index_pricing_rules_on_sellable_variant_id_and_priority"
    t.index ["sellable_variant_id"], name: "index_pricing_rules_on_sellable_variant_id"
  end

  create_table "products", force: :cascade do |t|
    t.integer "brand_id"
    t.integer "category_id"
    t.datetime "created_at", null: false
    t.integer "sellable_id", null: false
    t.string "sku_base"
    t.datetime "updated_at", null: false
    t.json "variant_dimensions"
    t.index ["brand_id"], name: "index_products_on_brand_id"
    t.index ["category_id"], name: "index_products_on_category_id"
    t.index ["sellable_id"], name: "index_products_on_sellable_id", unique: true
  end

  create_table "sellable_variants", force: :cascade do |t|
    t.json "attributes"
    t.datetime "created_at", null: false
    t.boolean "is_active", default: true, null: false
    t.decimal "price_override", precision: 10, scale: 2
    t.integer "sellable_id", null: false
    t.string "sku"
    t.datetime "updated_at", null: false
    t.string "variant_name", null: false
    t.index ["sellable_id"], name: "index_sellable_variants_on_sellable_id"
    t.index ["sku"], name: "index_sellable_variants_on_sku", unique: true, where: "sku IS NOT NULL"
  end

  create_table "sellables", force: :cascade do |t|
    t.decimal "base_price", precision: 10, scale: 2, null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.boolean "is_active", default: true, null: false
    t.string "name", null: false
    t.string "sellable_type", null: false
    t.datetime "updated_at", null: false
    t.index ["sellable_type"], name: "index_sellables_on_sellable_type"
  end

  create_table "service_config_specs", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "data_type", null: false
    t.string "default_value"
    t.text "description"
    t.string "field_name", null: false
    t.json "options"
    t.boolean "required"
    t.integer "service_id", null: false
    t.decimal "unit_price", precision: 10, scale: 2, default: "0.0", null: false
    t.datetime "updated_at", null: false
    t.index ["service_id"], name: "index_service_config_specs_on_service_id"
  end

  create_table "service_fulfillments", force: :cascade do |t|
    t.integer "assigned_user_id"
    t.datetime "created_at", null: false
    t.integer "order_item_id", null: false
    t.json "result"
    t.datetime "scheduled_at"
    t.string "status", default: "scheduled", null: false
    t.datetime "updated_at", null: false
    t.index ["assigned_user_id"], name: "index_service_fulfillments_on_assigned_user_id"
    t.index ["order_item_id"], name: "index_service_fulfillments_on_order_item_id"
    t.index ["status"], name: "index_service_fulfillments_on_status"
  end

  create_table "services", force: :cascade do |t|
    t.integer "category_id"
    t.datetime "created_at", null: false
    t.boolean "requires_schedule", default: false, null: false
    t.integer "sellable_id", null: false
    t.string "service_type", null: false
    t.text "terms"
    t.datetime "updated_at", null: false
    t.index ["category_id"], name: "index_services_on_category_id"
    t.index ["sellable_id"], name: "index_services_on_sellable_id", unique: true
  end

  create_table "shipping_addresses", force: :cascade do |t|
    t.string "apartment_details"
    t.string "city", null: false
    t.datetime "created_at", null: false
    t.string "district"
    t.integer "order_id", null: false
    t.string "phone_number", null: false
    t.datetime "updated_at", null: false
    t.index ["order_id"], name: "index_shipping_addresses_on_order_id"
  end

  create_table "specifications", force: :cascade do |t|
    t.integer "category_attribute_id", null: false
    t.datetime "created_at", null: false
    t.integer "sellable_id", null: false
    t.datetime "updated_at", null: false
    t.string "value", null: false
    t.index ["category_attribute_id"], name: "index_specifications_on_category_attribute_id"
    t.index ["sellable_id", "category_attribute_id"], name: "index_specs_on_sellable_and_attribute", unique: true
    t.index ["sellable_id"], name: "index_specifications_on_sellable_id"
  end

  create_table "subscription_plans", force: :cascade do |t|
    t.string "billing_cycle", null: false
    t.integer "company_id"
    t.datetime "created_at", null: false
    t.decimal "price", precision: 10, scale: 2, null: false
    t.integer "sellable_id", null: false
    t.integer "trial_days", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_subscription_plans_on_company_id"
    t.index ["sellable_id"], name: "index_subscription_plans_on_sellable_id"
  end

  create_table "user_subscriptions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "end_date"
    t.date "start_date", null: false
    t.string "status", null: false
    t.integer "subscription_plan_id", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["subscription_plan_id"], name: "index_user_subscriptions_on_subscription_plan_id"
    t.index ["user_id", "status"], name: "index_user_subscriptions_on_user_id_and_status"
    t.index ["user_id"], name: "index_user_subscriptions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.boolean "admin", default: false, null: false
    t.integer "company_id"
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "encrypted_password", default: "", null: false
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.string "role", default: "customer", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_users_on_company_id"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "cart_items", "carts"
  add_foreign_key "cart_items", "sellable_variants"
  add_foreign_key "cart_items", "sellables"
  add_foreign_key "carts", "users"
  add_foreign_key "categories", "categories", column: "parent_id"
  add_foreign_key "category_attributes", "categories"
  add_foreign_key "companies", "companies", column: "parent_company_id"
  add_foreign_key "inventories", "sellable_variants"
  add_foreign_key "order_items", "orders"
  add_foreign_key "order_items", "sellable_variants"
  add_foreign_key "order_items", "sellables"
  add_foreign_key "orders", "users"
  add_foreign_key "pricing_rules", "companies"
  add_foreign_key "pricing_rules", "companies", column: "sub_company_id"
  add_foreign_key "pricing_rules", "sellable_variants"
  add_foreign_key "pricing_rules", "sellables"
  add_foreign_key "products", "brands"
  add_foreign_key "products", "categories"
  add_foreign_key "products", "sellables"
  add_foreign_key "sellable_variants", "sellables"
  add_foreign_key "service_config_specs", "services"
  add_foreign_key "service_fulfillments", "order_items"
  add_foreign_key "service_fulfillments", "users", column: "assigned_user_id"
  add_foreign_key "services", "categories"
  add_foreign_key "services", "sellables"
  add_foreign_key "shipping_addresses", "orders"
  add_foreign_key "specifications", "category_attributes"
  add_foreign_key "specifications", "sellables"
  add_foreign_key "subscription_plans", "companies"
  add_foreign_key "subscription_plans", "sellables"
  add_foreign_key "user_subscriptions", "subscription_plans"
  add_foreign_key "user_subscriptions", "users"
  add_foreign_key "users", "companies"
end
