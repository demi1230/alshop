# AlShop Architecture Guide

A comprehensive guide to understanding the system design, patterns, and philosophy behind AlShop.

## 🏗️ System Overview

AlShop is a modern e-commerce platform built with clean architecture principles and CQRS (Command Query Responsibility Segregation) patterns. The system is designed for maintainability, testability, and scalability.

```
┌─────────────────────────────────────────────────────┐
│                   Web Layer                         │
│         Controllers → Views (HTML + JSON)           │
└────────────────────────┬────────────────────────────┘
                         │
┌────────────────────────▼────────────────────────────┐
│              Application Layer                      │
│    Services, Queries, Commands, Transactions       │
└────────────────────────┬────────────────────────────┘
                         │
┌────────────────────────▼────────────────────────────┐
│              Domain Layer                          │
│   Models, Validations, Business Rules              │
└────────────────────────┬────────────────────────────┘
                         │
┌────────────────────────▼────────────────────────────┐
│           Infrastructure Layer                     │
│   Database, File Storage, External Services        │
└─────────────────────────────────────────────────────┘
```

## 🎯 Design Principles

### 1. CQRS (Command Query Responsibility Segregation)

The application strictly separates **Commands** (state-changing operations) from **Queries** (read operations).

**Commands** (Write Operations):
- Change the system state
- Always wrapped in transactions
- Explicit error handling with Result objects
- Located in `app/services/` with descriptive names

Example:
```ruby
# CartToOrderService - converts cart to order (command)
result = CartToOrderService.call(cart, params)
if result.success?
  redirect_to order_path(result.order)
else
  render :checkout, alert: result.error
end
```

**Queries** (Read Operations):
- Never modify state
- Fast, optimized database queries
- Clean, reusable query objects
- Return plain objects or arrays

Example:
```ruby
# Get discounted products in a category
products = Product
  .where(category_id: category_id)
  .joins(:pricing_rules)
  .where(pricing_rules: { discount_type: ['percentage', 'fixed'] })
  .distinct
```

### 2. No ActiveRecord Callbacks

**Why?** Callbacks make testing difficult and behavior implicit.

❌ **Don't do this:**
```ruby
class Order < ApplicationRecord
  after_create :send_confirmation_email
  after_payment :update_inventory
end
```

✅ **Do this instead:**
```ruby
# In the service that creates the order
class Orders::Create < ApplicationService
  def call
    order = Order.create!(order_params)
    InventoryService.update(order)
    OrderMailer.confirmation(order).deliver_later
    Result.success(order)
  end
end
```

**Benefits:**
- Explicit side effects
- Easy to test
- Clear dependencies
- Chainable operations

### 3. Result Objects for Consistent Error Handling

All service objects return `Result` objects, never raise exceptions.

```ruby
# Service usage pattern
result = SomeService.call(params)

if result.success?
  # Handle success
  process(result.data)
else
  # Handle failure with clear error message
  logger.warn(result.error)
  notify_user(result.error)
end
```

**Result Object Structure:**
```ruby
class Result
  attr_reader :success, :data, :error
  
  def initialize(success:, data: nil, error: nil)
    @success = success
    @data = data
    @error = error
  end
  
  def success?
    @success == true
  end
end
```

### 4. Explicit Transactions

All state-changing operations wrap their logic in explicit transactions.

```ruby
def call(order)
  ActiveRecord::Base.transaction do
    order.update!(status: 'paid')
    inventory.decrement(order.items)
    accounting.record_sale(order)
    result_success(order)
  end
rescue StandardError => e
  result_error(e.message)
end
```

**Benefits:**
- Prevents partial updates
- Clear transaction boundaries
- Easy to reason about data consistency
- Automatic rollback on error

## 📁 Project Organization

### Controllers (`app/controllers/`)

**Responsibility:** Handle HTTP requests and responses

**Types:**
1. **Public Controllers** - For customer-facing features
   - `ProductsController` - Product browsing
   - `ServicesController` - Service browsing
   - `CartsController` - Shopping cart
   - `OrdersController` - Order management

2. **API Controllers** - JSON endpoints
   - `Api::ProductsController` - Product JSON API
   - `Api::CategoriesController` - Category JSON API

3. **Admin Controllers** - Admin panel
   - `Admin::ProductsController` - Admin product management
   - `Admin::CategoriesController` - Admin category management
   - `Admin::DashboardController` - Admin dashboard

**Controller Design:**
```ruby
class ProductsController < ApplicationController
  def index
    # 1. Set up filters/scopes
    @products = policy_scope(Product).includes(:category, :brand)
    
    # 2. Apply filters from params
    @products = @products.search(params[:q]) if params[:q]
    @products = @products.where(category_id: params[:category_id]) if params[:category_id]
    
    # 3. Handle pagination
    @products = @products.paginate(page: params[:page])
    
    # 4. Set instance variables for view
    @categories = Category.roots
  end
end
```

### Models (`app/models/`)

**Responsibility:** Domain logic and validations

**Key Models:**

| Model | Purpose | Relationships |
|-------|---------|---------------|
| `Product` | Retail product | belongs_to :category, :brand |
| `Service` | Service offering | belongs_to :category |
| `Category` | Product/service category | has_many :children, :products |
| `Order` | Customer order | has_many :order_items |
| `Cart` | Shopping cart | has_many :cart_items |
| `User` | User account | has_many :orders |
| `Brand` | Product brand | has_many :products |
| `PricingRule` | Discount/pricing logic | belongs_to :sellable |

**Model Design Principles:**

1. **Keep models thin** - Only domain logic, no application logic
```ruby
class Product < ApplicationRecord
  # ✅ Domain validations
  validates :name, presence: true
  
  # ✅ Domain associations
  belongs_to :category
  has_many :pricing_rules
  
  # ❌ Don't do application logic here
  # def create_order
  # def send_email
end
```

2. **Use scopes for queries**
```ruby
class Product < ApplicationRecord
  scope :in_category_tree, ->(category_id) do
    where(category_id: Category.descendant_ids_for(category_id))
  end
  
  scope :with_discount, -> do
    joins(:pricing_rules)
      .where(pricing_rules: { discount_type: ['percentage', 'fixed'] })
      .distinct
  end
end
```

3. **Delegated types for polymorphism**
```ruby
class Product < ApplicationRecord
  belongs_to :sellable, polymorphic: true
  # Now Product can have sellable_type: "Product" or "Service"
end
```

### Services (`app/services/`)

**Responsibility:** Application logic and business workflows

**Types:**

#### 1. Command Services (State-Changing Operations)

```ruby
# Example: Convert cart to order
class CartToOrderService
  def initialize(cart:, user:)
    @cart = cart
    @user = user
  end
  
  def call
    ActiveRecord::Base.transaction do
      order = Order.create!(user: @user, total: @cart.total)
      
      @cart.items.each do |item|
        OrderItem.create!(
          order: order,
          product: item.product,
          quantity: item.quantity,
          price: item.price
        )
      end
      
      @cart.update!(status: 'converted')
      
      Result.success(order: order)
    rescue StandardError => e
      Result.error(e.message)
    end
  end
end

# Usage:
result = CartToOrderService.new(cart: @cart, user: current_user).call
if result.success?
  redirect_to order_path(result.order)
end
```

#### 2. Calculator Services (Complex Calculations)

```ruby
# Example: Calculate dynamic pricing
class PricingCalculator
  def self.calculate(sellable:, channel:, company_id: nil)
    base_price = sellable.base_price
    
    # Apply channel-specific pricing
    channel_price = ChannelPricing.find_by(
      sellable: sellable,
      channel: channel
    )&.price || base_price
    
    # Apply company-specific pricing
    company_price = company_id ? 
      CompanyPricing.find_by(sellable: sellable, company_id: company_id)&.price : 
      nil
    
    # Apply active discounts
    discount = PricingRule
      .where(sellable: sellable)
      .where('valid_from <= ?', Time.current)
      .where('valid_to >= ?', Time.current)
      .first
    
    final_price = company_price || channel_price || base_price
    
    # Apply discount
    if discount
      final_price = case discount.discount_type
      when 'percentage'
        final_price * (1 - discount.discount_value / 100.0)
      when 'fixed'
        [final_price - discount.discount_value, 0].max
      end
    end
    
    {
      base_price: base_price,
      final_price: final_price,
      discount_applied: discount,
      channel_price: channel_price,
      company_price: company_price
    }
  end
end

# Usage:
pricing = PricingCalculator.calculate(
  sellable: @product.sellable,
  channel: 'mobile_app',
  company_id: company.id
)
```

### Views (`app/views/`)

**Responsibility:** Render HTML and JSON responses

**Organization:**
```
app/views/
├── layouts/
│   ├── application.html.erb      # Main layout
│   └── admin.html.erb            # Admin layout
│
├── products/
│   ├── index.html.erb            # Product listing
│   ├── show.html.erb             # Product detail
│   └── _card.html.erb            # Product card component
│
├── admin/
│   └── products/
│       ├── index.html.erb        # Admin product list
│       ├── new.html.erb          # Create product form
│       └── edit.html.erb         # Edit product form
│
└── shared/
    ├── _navbar.html.erb          # Navigation
    └── _footer.html.erb          # Footer
```

**View Best Practices:**

1. **Keep logic minimal in views**
```erb
<!-- ✅ Good: Simple interpolation -->
<h1><%= @product.name %></h1>
<p><%= @product.description %></p>

<!-- ❌ Bad: Complex logic -->
<% if @product.pricing_rules.where('valid_from <= ?', Time.current).any? %>
  <% discount = @product.pricing_rules.where('valid_from <= ?', Time.current).first %>
  <!-- ... -->
<% end %>
```

2. **Use partials for reusable components**
```erb
<!-- app/views/products/index.html.erb -->
<div class="grid">
  <% @products.each do |product| %>
    <%= render 'products/card', product: product %>
  <% end %>
</div>

<!-- app/views/products/_card.html.erb -->
<div class="card">
  <h3><%= product.name %></h3>
  <p><%= product.price %></p>
  <%= link_to 'View', product_path(product) %>
</div>
```

### JavaScript (`app/javascript/`)

**Responsibility:** Frontend interactivity and dynamic behavior

**Stimulus Controllers:**
```
app/javascript/controllers/
├── product_filter_controller.js   # Product search & filtering
└── category_filter_controller.js  # Category dropdown
```

**Example Stimulus Controller:**
```javascript
import { Controller } from "@hotwired/stimulus"

// Handles debounced search input
export default class extends Controller {
  static targets = ["searchInput", "submitButton"]
  static values = { debounceDelay: { type: Number, default: 500 } }

  connect() {
    this.timeout = null
  }

  debounceSearch(event) {
    // Clear existing timeout
    if (this.timeout) {
      clearTimeout(this.timeout)
    }

    // Set new timeout for submission
    this.timeout = setTimeout(() => {
      this.element.requestSubmit()
    }, this.debounceDelayValue)
  }
}
```

## 🔄 Request Flow

### 1. Product Listing Request

```
User visits /products?q=laptop
        ↓
ProductsController#index
        ↓
Fetch products with filters (scope chaining)
        ↓
Apply pagination
        ↓
Load categories for filter sidebar
        ↓
Render index.html.erb
        ↓
JavaScript controllers enhance with dynamic behavior
        ↓
User sees filtered product listing
```

### 2. Add to Cart Flow

```
User clicks "Add to Cart" button
        ↓
CartItemsController#create
        ↓
Validate product exists & availability
        ↓
Find or create cart
        ↓
Add/update cart item
        ↓
Return JSON response
        ↓
Stimulus controller updates cart count
        ↓
Show success notification
```

### 3. Checkout Flow

```
User clicks "Checkout"
        ↓
OrdersController#create
        ↓
CartToOrderService.call(cart)
        ↓
  ├─ Create Order record
  ├─ Create OrderItems from CartItems
  ├─ Update inventory
  ├─ Send confirmation email
  └─ Return success/error Result
        ↓
If success: Redirect to order confirmation
If error: Show error message
```

## 🧪 Testing Architecture

### Test Organization

```
test/
├── models/              # Model validations and scopes
├── controllers/         # Controller behavior and routing
├── services/           # Service object behavior
└── integration/        # End-to-end workflows
```

### Testing Patterns

**1. Model Tests:**
```ruby
describe Product do
  it 'validates presence of name' do
    product = Product.new(name: nil)
    expect(product).not_to be_valid
    expect(product.errors[:name]).to be_present
  end
  
  it 'scopes to category tree correctly' do
    parent = Category.create!(name: 'Electronics')
    child = Category.create!(name: 'Phones', parent: parent)
    
    product1 = Product.create!(name: 'iPhone', category: child)
    product2 = Product.create!(name: 'Laptop', category: parent)
    
    results = Product.in_category_tree(parent.id)
    expect(results).to include(product1, product2)
  end
end
```

**2. Service Tests:**
```ruby
describe CartToOrderService do
  it 'converts cart to order' do
    cart = create(:cart_with_items)
    user = create(:user)
    
    result = CartToOrderService.new(cart: cart, user: user).call
    
    expect(result).to be_success
    expect(result.order).to be_persisted
    expect(result.order.items.count).to eq(cart.items.count)
  end
  
  it 'returns error on invalid cart' do
    cart = create(:cart) # Empty
    user = create(:user)
    
    result = CartToOrderService.new(cart: cart, user: user).call
    
    expect(result).not_to be_success
    expect(result.error).to include('empty')
  end
end
```

**3. Controller Tests:**
```ruby
describe ProductsController do
  describe '#index' do
    it 'shows all products' do
      create_list(:product, 3)
      
      get :index
      
      expect(response).to be_successful
      expect(assigns(:products).count).to eq(3)
    end
    
    it 'filters by category' do
      electronics = create(:category)
      create(:product, category: electronics)
      create(:product) # Different category
      
      get :index, params: { category_id: electronics.id }
      
      expect(assigns(:products).count).to eq(1)
    end
  end
end
```

## 📊 Data Flow Diagram

```
┌──────────────┐
│   Browser   │
│  (HTML/CSS) │
└──────┬───────┘
       │ HTTP Request
       ▼
┌──────────────────────────────┐
│   Rails Router               │
│ (config/routes.rb)           │
└──────┬───────────────────────┘
       │ Route matches
       ▼
┌──────────────────────────────┐
│   Controller                 │
│ (ProductsController#index)   │
└──────┬───────────────────────┘
       │ Calls service or query
       ▼
┌──────────────────────────────┐
│   Service/Query              │
│ (Database operations)        │
└──────┬───────────────────────┘
       │ Returns data
       ▼
┌──────────────────────────────┐
│   View Template              │
│ (ERB → HTML)                 │
└──────┬───────────────────────┘
       │ HTML sent to browser
       ▼
┌──────────────────────────────┐
│   Browser Rendering          │
│ + Stimulus JS interactions   │
└──────────────────────────────┘
```

## 🔐 Security Architecture

### Authentication Flow

```
1. User submits login form (Devise)
        ↓
2. Credentials verified
        ↓
3. Session created (encrypted cookie)
        ↓
4. User object stored in @current_user
        ↓
5. All subsequent requests include session
```

### Authorization Flow

```
1. Controller before_action :authenticate_user!
        ↓
2. Pundit policy checked: authorize @resource
        ↓
3. Policy method called (e.g., show?, edit?)
        ↓
4. Returns true/false
        ↓
5. If false: Raise Pundit::NotAuthorizedError
        ↓
6. Rescued and show 403 Forbidden
```

## 📈 Scalability Considerations

### Database Query Optimization

1. **Eager Loading (N+1 Prevention)**
```ruby
# ❌ N+1 Query Problem
@products = Product.all
@products.each do |product|
  product.category.name  # Separate query per product
end

# ✅ Eager loaded
@products = Product.includes(:category)
```

2. **Pagination**
```ruby
# Always paginate large result sets
@products = @products.paginate(page: params[:page], per_page: 20)
```

3. **Selective Loading**
```ruby
# Only fetch needed columns
@products = Product.select(:id, :name, :price).all
```

### Caching Strategy

1. **Fragment Caching** - Cache rendered HTML
2. **Query Result Caching** - Cache database results
3. **HTTP Caching** - Cache at HTTP level

### Database Indexing

Key indexes:
- `categories` - `parent_id` (hierarchy traversal)
- `products` - `category_id` (filtering)
- `products` - `name` (search)
- `orders` - `user_id` (order lookup)
- `cart_items` - `cart_id` (cart display)

## 🚀 Deployment Architecture

### Docker Container Flow

```
Dockerfile
   ↓
Build image (precompile assets, install gems)
   ↓
Run container (Puma server)
   ↓
Expose port 3000
   ↓
Serve HTTP requests
```

### Environment Management

```
Development (.env)
├─ SQLite database
├─ Hot reloading enabled
└─ Debug logging

Production (Railway)
├─ SQLite or Postgres
├─ Asset compression
├─ Error tracking
└─ Performance monitoring
```

## 📚 Reference

### Configuration Files

| File | Purpose |
|------|---------|
| `config/routes.rb` | URL routing |
| `config/database.yml` | Database configuration |
| `config/application.rb` | App-wide settings |
| `Gemfile` | Ruby dependencies |
| `.env` | Environment variables |

### Key Directories

| Directory | Purpose |
|-----------|---------|
| `app/` | Application code |
| `config/` | Configuration |
| `db/` | Database |
| `test/` | Tests |
| `public/` | Static assets |
| `log/` | Application logs |

---

**Last Updated:** January 29, 2026  
**Version:** 1.0.0
