# Commerce Platform - Implementation Summary

## Overview
Successfully implemented a scalable commerce platform with unified Sellable abstraction supporting physical products, services, and dynamic pricing.

## Architecture Decisions

### 1. Sellable Pattern: Delegated Type
- **Choice**: Delegated Type (Rails 6.1+) over STI or pure polymorphic
- **Structure**: 
  - `Sellable` table stores common attributes (id, name, base_price, type)
  - `Product` and `Service` tables linked via one-to-one FK to Sellable
  - All associations reference `Sellable` directly
- **Benefits**: Clean queries, single FK target, no NULL column proliferation

### 2. Pricing Strategy: First-Match Resolution
- **Logic**: Rules sorted by priority (DESC), first match wins
- **Channels**: public < company < sub_company < partner < promo
- **Scope**: Global → Sellable-level → Variant-level (most specific wins)
- **Implementation**: `PricingRule` model with validations for context-specific fields

### 3. Order Snapshotting
- **Captured Fields**: `price_at_purchase`, `line_total`, `config_snapshot` (JSON)
- **Immutability**: OrderItem has no recalculation logic, displays historical data only
- **Purpose**: Legal compliance, prevents data loss from sellable/pricing changes

### 4. Fulfillment Separation
- **Aggregate Boundary**: Order + OrderItems (atomic) vs ServiceFulfillment (async)
- **Lifecycle**: Order created → Payment confirmed → Fulfillment triggered
- **States**: scheduled → ongoing → completed/cancelled

## Database Schema

### Core Tables (21 total)
1. **Identity & Organization**: users, companies
2. **Catalog**: brands, categories, category_attributes, sellables, products, services, sellable_variants
3. **Specification**: specifications, service_config_specs
4. **Pricing**: pricing_rules, subscription_plans
5. **Cart**: carts, cart_items
6. **Order**: orders, order_items, shipping_addresses
7. **Subscription**: user_subscriptions
8. **Fulfillment**: service_fulfillments
9. **Inventory**: inventories

### Key Constraints
- Foreign key constraints on all relationships
- Check constraints: `quantity > 0` on cart/order items, `quantity >= 0` on inventory
- Unique indexes: user email, cart (user + active status), variant SKU, inventory (variant + warehouse)
- NOT NULL on business-critical fields

### JSON Fields (SQLite compatible)
- `sellable_variants.attributes` - variant characteristics
- `cart_items.configuration` - service parameters
- `order_items.config_snapshot` - historical snapshot
- `service_fulfillments.result` - logs/notes
- `orders.metadata` - flexible order data

## Model Relationships

### Sellable (Delegated Type)
```ruby
Sellable
  └─ delegated_type: :sellable_entity (Product | Service)
  └─ has_many: sellable_variants, pricing_rules, specifications
```

### Product & Service
```ruby
Product
  └─ belongs_to: sellable, category, brand
  └─ delegates: name, base_price to sellable

Service
  └─ belongs_to: sellable, category
  └─ has_many: service_config_specs
  └─ enum: service_type (hourly/fixed/subscription)
```

### Cart → Order Flow
```ruby
Cart (mutable)
  └─ has_many: cart_items
  └─ status: active → converted/abandoned

Order (immutable)
  └─ has_many: order_items
  └─ status: pending → paid → shipped/cancelled
  └─ total_price: snapshot at checkout
```

### Pricing
```ruby
PricingRule
  └─ belongs_to: sellable, sellable_variant, company (optional)
  └─ enum: channel (public_channel/company/sub_company/partner/promo)
  └─ enum: discount_type (percentage/fixed/override)
  └─ validates: context-specific fields, date ranges
```

## Confirmed Assumptions

1. ✅ Services may optionally have variants
2. ✅ Inventory tracking applies only to physical products
3. ✅ Subscription services billed via recurring orders
4. ✅ Pricing uses first-match rule resolution
5. ✅ JSON acceptable for service configuration and snapshots

## Implementation Notes

### Enums
- All status fields use Rails 7.x enum with string values
- `PricingRule.channel` uses `public_channel` prefix to avoid Ruby reserved word conflict

### Validations
- Presence validations on all required fields
- Numericality checks on prices and quantities
- Custom validations for business rules (e.g., company required for company channel)
- Uniqueness constraints match DB indexes

### Scopes
- `active` scopes on Sellable, SellableVariant, Cart, PricingRule
- `by_priority` on PricingRule for sorting
- `paid`, `recent` on Order

## Next Steps (NOT IMPLEMENTED YET)

### Phase 1: Business Logic
- [ ] PricingEngine service object
- [ ] CartCheckout service object
- [ ] OrderFulfillment workflow

### Phase 2: API Layer
- [ ] RESTful controllers for catalog, cart, orders
- [ ] Authentication & authorization
- [ ] Admin panel

### Phase 3: Background Jobs
- [ ] Subscription billing job
- [ ] Cart expiration job
- [ ] Inventory sync job

### Phase 4: Extensions
- [ ] Tax calculation
- [ ] Shipping cost calculation
- [ ] Payment gateway integration
- [ ] Email notifications

## Files Generated

### Migrations (21)
- All located in `db/migrate/`
- Timestamp range: 20260118160916 - 20260118161041
- SQLite compatible (using `json` instead of `jsonb`)

### Models (21)
- All located in `app/models/`
- Includes associations, validations, enums, scopes
- No business logic yet (as requested)

### Dependencies Added
- `bcrypt` for User password hashing

## Testing
All 21 models load successfully with zero errors. Database schema is clean and ready for development.
