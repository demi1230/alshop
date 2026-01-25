# REFACTORING PLAN: CQRS → Rails Best Practices
# Internship Portfolio Project Architecture
# Date: January 19, 2026

## EXECUTIVE SUMMARY

**Current State:** Over-engineered CQRS architecture (239 tests, 7 services, 4 queries)
**Target State:** Clean Rails monolith following conventions
**Why:** Demonstrate Rails fundamentals for internship portfolio, not production architecture

---

## PART 1: ARCHITECTURAL PHILOSOPHY

### What Good Internship Projects Show

**✅ DO Show:**
- Strong ActiveRecord fundamentals
- RESTful controller design
- Model-driven business logic
- Clean associations and validations
- Appropriate use of concerns
- Standard Rails patterns (callbacks when appropriate!)
- Role-based authorization
- Test coverage

**❌ DON'T Show:**
- CQRS in a monolith
- Query objects for simple scopes
- Service objects for everything
- Domain events without event sourcing
- Premature abstractions

### The Rails Way

> "Convention over Configuration"
> Put logic where Rails expects it:
> - Models: Business logic, validations, scopes
> - Controllers: HTTP handling, thin
> - Views: Presentation
> - Services: Only for complex multi-model coordination

---

## PART 2: SIMPLIFIED ARCHITECTURE

### Directory Structure (After Refactoring)

```
app/
├── models/
│   ├── user.rb                    # Devise + role enum
│   ├── category.rb                # Product categorization
│   ├── sellable.rb                # Delegated type base
│   ├── product.rb                 # Delegates to Sellable
│   ├── service.rb                 # Delegates to Sellable (minimal)
│   ├── sellable_variant.rb        # Product variants
│   ├── cart.rb                    # Belongs to user
│   ├── cart_item.rb               # Cart line items
│   ├── order.rb                   # ⭐ BUSINESS LOGIC HERE
│   ├── order_item.rb              # Order line items with price snapshot
│   ├── shipping_address.rb        # Order shipping
│   ├── pricing_rule.rb            # Optional pricing rules
│   └── concerns/
│       ├── priceable.rb           # Shared pricing logic
│       └── orderable.rb           # Order state machine logic
│
├── controllers/
│   ├── application_controller.rb  # Devise + Pundit setup
│   ├── products_controller.rb     # Public browsing + admin CRUD
│   ├── carts_controller.rb        # Cart management
│   ├── orders_controller.rb       # Place order, view orders
│   └── admin/
│       ├── products_controller.rb # Admin product management
│       ├── orders_controller.rb   # Admin order management
│       └── dashboard_controller.rb
│
├── services/
│   ├── cart_to_order_service.rb   # KEEP: Multi-step order creation
│   └── pricing_calculator.rb      # KEEP: Complex pricing logic
│
├── policies/                       # Pundit authorization
│   ├── product_policy.rb
│   ├── order_policy.rb
│   └── admin_policy.rb
│
└── views/
    ├── products/
    ├── carts/
    ├── orders/
    └── admin/
```

### What Got Deleted

```
❌ app/queries/                     # ALL query objects deleted
❌ app/services/orders/             # Order command services deleted
❌ app/services/revenue/            # Report service deleted
❌ app/services/orders/detail_summary.rb  # Moved to Order model
❌ Domain events (BaseEvent, etc.)  # Completely removed
```

---

## PART 3: MODEL DESIGN (Rails-First)

### Core Models with Responsibilities

#### 1. User (Devise + Roles)

```ruby
# app/models/user.rb
class User < ApplicationRecord
  devise :database_authenticatable, :registerable, :recoverable, :rememberable, :validatable
  
  enum role: { customer: 0, admin: 1, staff: 2 }
  
  has_one :cart, dependent: :destroy
  has_many :orders, dependent: :destroy
  belongs_to :company, optional: true
  
  after_create :create_cart
  
  def admin?
    role == 'admin'
  end
  
  def customer?
    role == 'customer'
  end
end
```

**Why:** Standard Devise setup, enum for roles, simple helper methods

---

#### 2. Product (Core Domain)

```ruby
# app/models/product.rb
class Product < ApplicationRecord
  belongs_to :sellable, dependent: :destroy
  
  has_many :sellable_variants, through: :sellable
  belongs_to :category, optional: true
  belongs_to :brand, optional: true
  
  validates :name, presence: true
  validates :base_price, numericality: { greater_than_or_equal_to: 0 }
  
  scope :active, -> { where(is_active: true) }
  scope :in_category, ->(category_id) { where(category_id: category_id) }
  scope :search, ->(query) { where("name LIKE ?", "%#{sanitize_sql_like(query)}%") }
  
  # Business logic in the model
  def current_price(user: nil, quantity: 1)
    PricingCalculator.calculate(sellable: sellable, user: user, quantity: quantity)
  end
  
  def available_variants
    sellable_variants.where(is_active: true)
  end
  
  def in_stock?
    # Simplified - could check inventory
    is_active?
  end
end
```

**Why:**
- Business logic lives in the model
- Scopes for common queries (replaces query objects!)
- Methods return what they mean (`in_stock?`, `current_price`)
- Uses standard Rails patterns

---

#### 3. Order (Business Logic Hub)

```ruby
# app/models/order.rb
class Order < ApplicationRecord
  include Orderable  # State machine logic in concern
  
  belongs_to :user
  has_many :order_items, dependent: :destroy
  has_one :shipping_address, dependent: :destroy
  
  accepts_nested_attributes_for :shipping_address
  
  enum status: { 
    pending: 0, 
    paid: 1, 
    shipped: 2, 
    delivered: 3, 
    cancelled: 4 
  }
  
  validates :total_price, presence: true, numericality: { greater_than: 0 }
  
  # Scopes (replaces query objects)
  scope :recent, -> { order(created_at: :desc) }
  scope :for_user, ->(user) { where(user: user) }
  scope :by_status, ->(status) { where(status: status) }
  scope :in_date_range, ->(from, to) { where(created_at: from..to) }
  
  # Business logic methods (replaces service objects)
  def mark_as_paid!(payment_method:, transaction_id:)
    transaction do
      update!(
        status: :paid,
        metadata: (metadata || {}).merge(
          payment_method: payment_method,
          transaction_id: transaction_id,
          paid_at: Time.current.iso8601
        )
      )
      
      # Simple callback or direct call
      create_fulfillments_if_needed
    end
  end
  
  def mark_as_shipped!
    update!(status: :shipped)
  end
  
  def cancel!(reason: nil)
    transaction do
      update!(
        status: :cancelled,
        metadata: (metadata || {}).merge(
          cancellation_reason: reason,
          cancelled_at: Time.current.iso8601
        )
      )
      
      # Cancel any pending fulfillments
      service_fulfillments.pending.update_all(status: :cancelled)
    end
  end
  
  def total_refunded
    (metadata || {})['refunds']&.sum { |r| r['amount'].to_f } || 0
  end
  
  def net_amount
    total_price - total_refunded
  end
  
  def payment_method
    metadata&.dig('payment_method')
  end
  
  private
  
  def create_fulfillments_if_needed
    # Simple version - just create records
    order_items.joins(:sellable).where(sellables: { sellable_type: 'Service' }).find_each do |item|
      ServiceFulfillment.create!(
        order_item: item,
        status: :scheduled,
        scheduled_at: 3.days.from_now
      )
    end
  end
end
```

**Why:**
- All order business logic in ONE place
- Easy to understand state transitions
- Scopes replace query objects
- Methods are explicit (`mark_as_paid!` not `Orders::MarkPaid.call`)
- Transactions still used appropriately
- This is what Rails developers expect to see!

---

#### 4. Cart (Simple State Management)

```ruby
# app/models/cart.rb
class Cart < ApplicationRecord
  belongs_to :user
  has_many :cart_items, dependent: :destroy
  
  def add_item(sellable:, quantity: 1, variant: nil)
    existing = cart_items.find_by(
      sellable: sellable,
      sellable_variant: variant
    )
    
    if existing
      existing.increment!(:quantity, quantity)
      existing
    else
      cart_items.create!(
        sellable: sellable,
        sellable_variant: variant,
        quantity: quantity,
        price_at_add: sellable.base_price
      )
    end
  end
  
  def total_price
    cart_items.sum { |item| item.quantity * item.price_at_add }
  end
  
  def item_count
    cart_items.sum(:quantity)
  end
  
  def clear!
    cart_items.destroy_all
  end
end
```

**Why:**
- Simple, clear methods
- No need for service object
- Model owns its behavior

---

#### 5. Concern: Orderable (State Machine)

```ruby
# app/models/concerns/orderable.rb
module Orderable
  extend ActiveSupport::Concern
  
  included do
    # Validations
    validates :status, presence: true
    
    # Callbacks
    after_update :notify_status_change, if: :saved_change_to_status?
  end
  
  def can_be_paid?
    pending?
  end
  
  def can_be_shipped?
    paid?
  end
  
  def can_be_cancelled?
    pending? || paid?
  end
  
  private
  
  def notify_status_change
    # Could send email, log, etc.
    Rails.logger.info "Order #{id} status changed to #{status}"
  end
end
```

**Why:**
- Concerns for shared behavior
- Callbacks ARE OKAY when they make sense
- Clean, testable

---

## PART 4: CONTROLLER DESIGN (RESTful)

### 1. ProductsController (Public + Admin)

```ruby
# app/controllers/products_controller.rb
class ProductsController < ApplicationController
  before_action :authenticate_user!, only: [:new, :create, :edit, :update, :destroy]
  before_action :set_product, only: [:show, :edit, :update, :destroy]
  
  # GET /products
  def index
    @products = Product.active.includes(:category, :brand)
    @products = @products.in_category(params[:category_id]) if params[:category_id].present?
    @products = @products.search(params[:q]) if params[:q].present?
    @products = @products.page(params[:page]).per(20)
  end
  
  # GET /products/:id
  def show
    @variants = @product.available_variants
  end
  
  # Admin actions
  def new
    authorize :admin, :access?
    @product = Product.new
  end
  
  def create
    authorize :admin, :access?
    @product = Product.new(product_params)
    
    if @product.save
      redirect_to @product, notice: 'Product created successfully.'
    else
      render :new, status: :unprocessable_entity
    end
  end
  
  # ... standard REST actions
  
  private
  
  def set_product
    @product = Product.find(params[:id])
  end
  
  def product_params
    params.require(:product).permit(:name, :description, :base_price, :category_id, :is_active)
  end
end
```

**Why:**
- Standard REST conventions
- Kaminari pagination (or will_paginate)
- Pundit for authorization
- Simple, readable
- This is what interviewers expect!

---

### 2. OrdersController (Customer)

```ruby
# app/controllers/orders_controller.rb
class OrdersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_order, only: [:show]
  
  # GET /orders
  def index
    @orders = current_user.orders.recent.page(params[:page])
  end
  
  # GET /orders/:id
  def show
    authorize @order  # Pundit: can only view own orders
  end
  
  # POST /orders
  def create
    result = CartToOrderService.call(
      cart: current_user.cart,
      shipping_address_params: shipping_address_params
    )
    
    if result.success?
      redirect_to result.order, notice: 'Order placed successfully!'
    else
      redirect_to cart_path, alert: result.error
    end
  end
  
  private
  
  def set_order
    @order = Order.find(params[:id])
  end
  
  def shipping_address_params
    params.require(:shipping_address).permit(:full_name, :phone_number, :city, :district)
  end
end
```

**Why:**
- RESTful design
- ONE service object for complex multi-step operation (cart → order)
- Pundit for authorization
- Clear success/failure paths

---

### 3. Admin::OrdersController

```ruby
# app/controllers/admin/orders_controller.rb
class Admin::OrdersController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_admin
  before_action :set_order, only: [:show, :mark_paid, :mark_shipped, :cancel]
  
  def index
    @orders = Order.includes(:user, :order_items)
    @orders = @orders.by_status(params[:status]) if params[:status].present?
    @orders = @orders.recent.page(params[:page])
  end
  
  def show
    @order_items = @order.order_items.includes(:sellable)
  end
  
  # Custom action: POST /admin/orders/:id/mark_paid
  def mark_paid
    if @order.mark_as_paid!(
      payment_method: params[:payment_method],
      transaction_id: params[:transaction_id]
    )
      redirect_to admin_order_path(@order), notice: 'Order marked as paid.'
    else
      redirect_to admin_order_path(@order), alert: @order.errors.full_messages.join(', ')
    end
  end
  
  # Custom action: POST /admin/orders/:id/mark_shipped
  def mark_shipped
    if @order.mark_as_shipped!
      redirect_to admin_order_path(@order), notice: 'Order marked as shipped.'
    else
      redirect_to admin_order_path(@order), alert: @order.errors.full_messages.join(', ')
    end
  end
  
  # Custom action: POST /admin/orders/:id/cancel
  def cancel
    if @order.cancel!(reason: params[:reason])
      redirect_to admin_order_path(@order), notice: 'Order cancelled.'
    else
      redirect_to admin_order_path(@order), alert: @order.errors.full_messages.join(', ')
    end
  end
  
  private
  
  def set_order
    @order = Order.find(params[:id])
  end
  
  def authorize_admin
    redirect_to root_path, alert: 'Access denied.' unless current_user.admin?
  end
end
```

**Why:**
- Custom actions for state transitions (RESTful + member actions)
- Business logic in model, controller just coordinates
- Clear admin namespace
- Standard Rails patterns

---

## PART 5: SERVICE OBJECTS (Minimal)

### Only Keep 2 Service Objects

#### 1. CartToOrderService (Multi-Step Workflow)

```ruby
# app/services/cart_to_order_service.rb
class CartToOrderService
  attr_reader :cart, :shipping_address_params
  
  def self.call(**args)
    new(**args).call
  end
  
  def initialize(cart:, shipping_address_params:)
    @cart = cart
    @shipping_address_params = shipping_address_params
  end
  
  def call
    return failure('Cart is empty') if cart.cart_items.empty?
    
    ActiveRecord::Base.transaction do
      order = create_order
      create_order_items(order)
      create_shipping_address(order)
      cart.clear!
      
      success(order: order)
    end
  rescue ActiveRecord::RecordInvalid => e
    failure(e.message)
  end
  
  private
  
  def create_order
    Order.create!(
      user: cart.user,
      status: :pending,
      total_price: calculate_total,
      metadata: {}
    )
  end
  
  def create_order_items(order)
    cart.cart_items.each do |cart_item|
      price = PricingCalculator.calculate(
        sellable: cart_item.sellable,
        user: cart.user,
        quantity: cart_item.quantity
      )
      
      OrderItem.create!(
        order: order,
        sellable: cart_item.sellable,
        sellable_variant: cart_item.sellable_variant,
        quantity: cart_item.quantity,
        price_at_purchase: price,
        line_total: price * cart_item.quantity,
        config_snapshot: build_snapshot(cart_item)
      )
    end
  end
  
  def create_shipping_address(order)
    ShippingAddress.create!(
      order: order,
      **shipping_address_params
    )
  end
  
  def calculate_total
    # Simplified calculation
    cart.cart_items.sum { |item| item.quantity * item.price_at_add }
  end
  
  def build_snapshot(cart_item)
    {
      sellable_name: cart_item.sellable.name,
      sellable_type: cart_item.sellable.sellable_type,
      base_price: cart_item.sellable.base_price
    }
  end
  
  def success(order:)
    OpenStruct.new(success?: true, order: order, error: nil)
  end
  
  def failure(message)
    OpenStruct.new(success?: false, order: nil, error: message)
  end
end
```

**Why Keep:**
- Coordinates multiple models (Cart, Order, OrderItem, ShippingAddress)
- Complex transaction boundary
- Price snapshotting logic
- Too complex for model callback
- Clear service object use case

---

#### 2. PricingCalculator (Complex Business Logic)

```ruby
# app/services/pricing_calculator.rb
class PricingCalculator
  def self.calculate(sellable:, user: nil, quantity: 1)
    new(sellable: sellable, user: user, quantity: quantity).calculate
  end
  
  def initialize(sellable:, user:, quantity:)
    @sellable = sellable
    @user = user
    @quantity = quantity
  end
  
  def calculate
    base = @sellable.base_price
    rule = find_applicable_rule
    
    return base unless rule
    
    apply_discount(base, rule)
  end
  
  private
  
  def find_applicable_rule
    # Simplified: just find first matching rule
    PricingRule
      .where(sellable: @sellable, is_active: true)
      .where('min_quantity IS NULL OR min_quantity <= ?', @quantity)
      .order(priority: :asc)
      .first
  end
  
  def apply_discount(base, rule)
    if rule.discount_type == 'percentage'
      base * (1 - rule.discount_value / 100.0)
    else
      base - rule.discount_value
    end
  end
end
```

**Why Keep:**
- Complex pricing logic (quantity breaks, rules, priority)
- Pure calculation (no side effects)
- Reusable across cart, checkout, display
- Too complex for model method

---

## PART 6: WHAT TO DELETE

### Files to Delete Completely

```bash
# Query objects (all of them)
rm -rf app/queries/

# Order command services (business logic moves to Order model)
rm app/services/orders/mark_paid.rb
rm app/services/orders/cancel.rb
rm app/services/orders/refund.rb
rm app/services/orders/detail_summary.rb

# Revenue report (Phase 2, if needed, will be model methods)
rm app/services/revenue/report.rb
rm app/queries/revenue/

# Domain events (not needed)
rm app/services/orders/events.rb

# Fulfillment orchestration (simplified, moves to Order model)
rm app/services/fulfillment_orchestration_service.rb

# Tests for deleted files
rm -rf test/queries/
rm test/services/orders/mark_paid_test.rb
rm test/services/orders/cancel_test.rb
rm test/services/orders/refund_test.rb
rm test/services/revenue/report_test.rb
```

### Files to Refactor (Keep but Simplify)

```bash
# Keep with modifications:
app/services/cart_to_order_service.rb  # Simplify, remove Result pattern complexity
app/services/pricing_engine.rb         # Rename to pricing_calculator.rb, simplify

# Keep as-is:
All 21 migrations (they're fine)
All model files (add business logic to them)
```

---

## PART 7: IMPLEMENTATION PHASES

### Phase 1A: Foundation (Week 1)
**Goal:** Get basic Rails app structure working

1. **Add gems:**
   ```ruby
   gem 'devise'
   gem 'pundit'
   gem 'kaminari'  # or 'will_paginate'
   ```

2. **Setup Devise + Roles:**
   - `rails g devise:install`
   - Add `role` enum to User
   - Create admin seed user

3. **Setup Pundit:**
   - `rails g pundit:install`
   - Create basic policies

4. **Delete over-engineered code:**
   - Remove query objects
   - Remove order command services
   - Remove domain events

5. **Refactor models:**
   - Move Order business logic from services to model
   - Add scopes to replace query objects
   - Add Orderable concern

### Phase 1B: Customer Flow (Week 2)
**Goal:** Customer can browse and order

1. **Product browsing:**
   - ProductsController#index, #show
   - Views with Tailwind
   - Search and filters (model scopes)

2. **Cart management:**
   - CartsController
   - Cart#add_item, Cart#total_price
   - Cart view

3. **Order placement:**
   - OrdersController#create (uses CartToOrderService)
   - OrdersController#index, #show
   - Order confirmation view

### Phase 1C: Admin Panel (Week 3)
**Goal:** Admin can manage products and orders

1. **Admin namespace:**
   - Admin::ProductsController (full CRUD)
   - Admin::OrdersController (view, update status)
   - Admin layout

2. **Order status management:**
   - Order#mark_as_paid! (model method)
   - Order#mark_as_shipped! (model method)
   - Order#cancel! (model method)
   - Custom controller actions

3. **Authorization:**
   - Pundit policies
   - Admin-only access checks

---

## PART 8: TESTING STRATEGY

### What to Test (Simplified)

```ruby
# Model tests (most important!)
test/models/order_test.rb
  - State transitions (mark_as_paid!, cancel!, etc.)
  - Scopes (recent, by_status, etc.)
  - Calculations (total_refunded, net_amount)
  - Validations

test/models/cart_test.rb
  - add_item, total_price, item_count
  
# Service tests (only 2 services!)
test/services/cart_to_order_service_test.rb
  - Happy path
  - Empty cart
  - Transaction rollback
  
test/services/pricing_calculator_test.rb
  - Base price
  - Discount rules
  - Priority resolution

# Controller tests (system tests preferred)
test/controllers/products_controller_test.rb
  - index, show (public)
  - CRUD (admin only)
  
# System tests (user flows)
test/system/customer_orders_test.rb
  - Browse → Add to cart → Checkout → Order
  
test/system/admin_order_management_test.rb
  - View orders → Mark paid → Mark shipped
```

**Target:** ~80-100 tests (down from 239)
**Focus:** Core business logic, user flows, not infrastructure

---

## PART 9: COMPARISON (Before/After)

### Before: Over-Engineered CQRS

```ruby
# To mark order as paid (CQRS way):
result = Orders::MarkPaid.call(
  order: order,
  payment_method: 'stripe',
  transaction_id: 'ch_123'
)

if result.success?
  # Event emitted: OrderMarkedPaid
  # Fulfillment orchestration triggered
  # Domain event stored
end

# To list orders (Query Object way):
result = Orders::List.call(
  user_id: user.id,
  status: 'paid',
  page: 1
)
result.orders  # ActiveRecord::Relation
result.total_count
result.has_next_page?
```

**Problems:**
- Too many layers
- Hard to follow
- Not Rails conventions
- Confusing for interns/juniors

### After: Rails Best Practices

```ruby
# To mark order as paid (Rails way):
order.mark_as_paid!(
  payment_method: 'stripe',
  transaction_id: 'ch_123'
)

# To list orders (ActiveRecord way):
orders = Order.for_user(user).by_status('paid').recent.page(1)
orders.total_count  # Kaminari helper
```

**Benefits:**
- Clear, readable
- Standard Rails patterns
- Easy to understand
- What interviewers expect

---

## PART 10: SUCCESS CRITERIA

### This is a Good Internship Project When:

**✅ Code Quality:**
- [ ] Follows Rails conventions
- [ ] Business logic in models
- [ ] Controllers are thin
- [ ] DRY (concerns for shared behavior)
- [ ] Good naming conventions

**✅ Features Working:**
- [ ] User authentication (Devise)
- [ ] Customer can browse/order
- [ ] Admin can manage products/orders
- [ ] Authorization works (Pundit)
- [ ] Tests pass (80+ tests)

**✅ Documentation:**
- [ ] Clear README
- [ ] Setup instructions work
- [ ] ERD diagram
- [ ] Explains architectural choices

**✅ Interview Ready:**
- [ ] Can explain why Rails way, not CQRS
- [ ] Can walk through order placement flow
- [ ] Can explain model vs. service decision
- [ ] Shows understanding of trade-offs

---

## PART 11: NEXT STEPS

### If You Approve This Direction:

**Step 1: Delete Over-Engineering**
- I'll create a migration script to safely delete query objects, command services, domain events
- Keep only CartToOrderService and PricingCalculator

**Step 2: Refactor Order Model**
- Move business logic from services to Order model
- Add state transition methods
- Add scopes to replace query objects

**Step 3: Build Controllers**
- Standard REST controllers
- Admin namespace
- Pundit authorization

**Step 4: Views (ERB + Tailwind)**
- Product listing
- Cart
- Checkout
- Admin panel

**Step 5: Polish**
- Refactor tests
- Update documentation
- Create demo data

---

## QUESTIONS FOR YOU

1. **Do you approve this Rails-first refactoring?**
   - Remove CQRS, query objects, domain events
   - Business logic in models
   - Only 2 service objects

2. **Views or API?**
   - I assumed ERB views + Tailwind (more complete for internship)
   - Or do you want API-only for React frontend?

3. **Variants complexity?**
   - Keep full variant system (color, size)?
   - Or simplify to just Product with optional variants?

4. **Services vs. Products?**
   - Keep both with delegated types?
   - Or just focus on Products for simplicity?

5. **Timeline?**
   - This refactoring: ~1-2 weeks
   - Then Phase 1 features: ~2-3 weeks
   - Total: ~4-5 weeks to complete internship project

**This will be a STRONG internship portfolio project that demonstrates Rails competency, not over-engineering. Ready to proceed?**
