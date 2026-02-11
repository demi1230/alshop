# AlShop E-Commerce Platform - Системийн Дизайн Баримт Бичиг

## ХУРААНГУЙ

Энэхүү баримт бичигт AlShop e-commerce платформын системийн дизайн, архитектур, технологийн шийдлүүдийг дэлгэрэнгүй тайлбарласан болно. Систем нь Ruby on Rails 8.1 framework дээр бүтээгдсэн бөгөөд орчин үеийн web development практикууд болон SOLID зарчмуудыг дагасан.

---

## 1. СИСТЕМИЙН ДИЗАЙНЫ ФИЛОСОФИ

### 1.1 Дизайны Зорилго

AlShop системийг дизайнлахдаа дараах зорилгуудыг тавьсан:

1. **Хялбар засварлагдах (Maintainability)** - Код тодорхой, модульчлагдсан
2. **Өргөтгөх боломжтой (Scalability)** - Шинэ функц нэмэх хялбар
3. **Тестлэх боломжтой (Testability)** - Unit, integration тест бичих хялбар
4. **Гүйцэтгэл (Performance)** - Хурдан response time, оновчтой query
5. **Аюулгүй байдал (Security)** - Өгөгдлийн хамгаалалт, эрх удирдлага

### 1.2 SOLID Зарчмууд

Системийн дизайнд SOLID зарчмуудыг мөрдсөн:

- **S**ingle Responsibility - Нэг class нэг үүрэгтэй
- **O**pen/Closed - Өргөтгөхөд нээлттэй, өөрчлөхөд хаалттай
- **L**iskov Substitution - Дэд класс эх классыг орлох чадвартай
- **I**nterface Segregation - Жижиг, тусгай интерфейсүүд
- **D**ependency Inversion - Хийсвэрлэл дээр тулгуурласан

---

## 2. АРХИТЕКТУРЫН ЗАГВАР

### 2.1 MVC + Service Layer Architecture

Систем нь Model-View-Controller загварт Service Layer нэмсэн архитектур ашигласан:

```
┌─────────────────────────────────────────────┐
│              VIEW LAYER                     │
│  • HTML Templates (ERB)                     │
│  • Tailwind CSS                             │
│  • Stimulus JavaScript                      │
└─────────────────┬───────────────────────────┘
                  │
┌─────────────────▼───────────────────────────┐
│           CONTROLLER LAYER                  │
│  • Request handling                         │
│  • Parameter validation                     │
│  • Response rendering                       │
└─────────────────┬───────────────────────────┘
                  │
┌─────────────────▼───────────────────────────┐
│            SERVICE LAYER                    │
│  • Business logic                           │
│  • Transaction management                   │
│  • Complex operations                       │
└─────────────────┬───────────────────────────┘
                  │
┌─────────────────▼───────────────────────────┐
│             MODEL LAYER                     │
│  • Data persistence                         │
│  • Validations                              │
│  • Associations                             │
└─────────────────┬───────────────────────────┘
                  │
┌─────────────────▼───────────────────────────┐
│           DATABASE LAYER                    │
│  • PostgreSQL (Production)                  │
│  • SQLite3 (Development)                    │
└─────────────────────────────────────────────┘
```

### 2.2 Давхаргын Үүрэг

#### A) View Layer - Харуулах Давхарга
**Үүрэг**: Хэрэглэгчийн интерфейс, харилцан үйлдэл

**Технологи**:
- ERB (Embedded Ruby) templates
- Tailwind CSS - Utility-first CSS framework
- Stimulus JavaScript - Progressive JavaScript framework
- Turbo Rails - SPA-like navigation

**Дизайны шийдэл**:
- Component-based partial views
- Responsive mobile-first дизайн
- Accessibility (WCAG 2.1) стандарт
- Progressive enhancement

#### B) Controller Layer - Удирдлагын Давхарга
**Үүрэг**: HTTP хүсэлт боловсруулах, routing

**Зохион байгуулалт**:
```
app/controllers/
├── concerns/               # Shared functionality
├── products_controller.rb  # Public product browsing
├── services_controller.rb  # Public service browsing
├── carts_controller.rb     # Shopping cart
├── orders_controller.rb    # Order management
├── admin/                  # Admin namespace
│   ├── products_controller.rb
│   ├── orders_controller.rb
│   └── ... (14 controllers)
└── api/                    # API namespace
    ├── products_controller.rb
    └── categories_controller.rb
```

**Зарчим**: Thin controller - Logic-ийг service layer руу шилжүүлсэн

#### C) Service Layer - Бизнес Логик Давхарга
**Үүрэг**: Нарийн төвөгтэй бизнес логик, transaction удирдлага

**Service Objects**:
```ruby
# CartToOrderService - Сагсыг захиалга болгох
class CartToOrderService
  def self.call(cart:, shipping_address_params:)
    # Validation
    # Transaction
    # Order creation
    # Cart clearing
  end
end

# PricingCalculator - Үнэ тооцоолох
class PricingCalculator
  def self.calculate(sellable:, variant:, user:, quantity:)
    # Base price
    # Pricing rules
    # Discounts
    # Final price
  end
end
```

**Давуу тал**:
- Дахин ашиглах боломжтой
- Тестлэх хялбар
- Business logic ил тод
- Transaction бүрэн эрхлэлт

#### D) Model Layer - Өгөгдлийн Давхарга
**Үүрэг**: Domain logic, persistence, validation

**Үндсэн моделүүд** (23 модель):
- **Sellable** - Polymorphic эх (Product/Service)
- **Product** - Физик бараа
- **Service** - Үйлчилгээ
- **Category** - Давхар ангилал
- **Brand** - Брэнд
- **SellableVariant** - SKU, хувилбарууд
- **PricingRule** - Үнийн дүрэм
- **Cart/CartItem** - Сагс
- **Order/OrderItem** - Захиалга
- **User** - Хэрэглэгч
- **Inventory** - Нөөц бараа
- **SubscriptionPlan** - Subscription төлөвлөгөө
- **UserSubscription** - Хэрэглэгчийн subscription
- **ServiceFulfillment** - Үйлчилгээ гүйцэтгэл
- **Company** - B2B компани

---

## 3. ӨГӨГДЛИЙН САНД ДИЗАЙН

### 3.1 Database Schema Design Principles

**Normalization**: 3NF (Third Normal Form) баримталсан
- Data redundancy багасгасан
- Update anomaly-аас сэргийлсэн
- Referential integrity хадгалсан

**Denormalization**: Зарим тохиолдолд
- Order items - үнийн snapshot хадгалах
- Performance optimization

### 3.2 Polymorphic Association Pattern

Sellable модель нь Product болон Service-ийн эх модель болсон:

```
┌─────────────────────────────┐
│         Sellable            │
│ ─────────────────────────── │
│ + id                        │
│ + name                      │
│ + description               │
│ + base_price                │
│ + sellable_type             │
│ + is_active                 │
└─────────────┬───────────────┘
              │
       ┌──────┴──────┐
       │             │
┌──────▼──────┐ ┌───▼────────┐
│   Product   │ │  Service   │
├─────────────┤ ├────────────┤
│ sellable_id │ │sellable_id │
│ category_id │ │category_id │
│ brand_id    │ │service_type│
│ sku_base    │ │duration    │
└─────────────┘ └────────────┘
```

**Давуу тал**:
- Код давтагдахгүй (DRY)
- Pricing, variants ижил логик
- Шинэ sellable төрөл нэмэх хялбар

**Implementation**:
```ruby
class Sellable < ApplicationRecord
  has_one :product, dependent: :destroy
  has_one :service, dependent: :destroy
  has_many :sellable_variants
  has_many :pricing_rules
  
  validates :sellable_type, inclusion: { in: %w[Product Service] }
  
  def sellable_entity
    case sellable_type
    when 'Product' then product
    when 'Service' then service
    end
  end
end
```

### 3.3 Category Hierarchy Design

Self-referential tree бүтэц:

```sql
CREATE TABLE categories (
  id INTEGER PRIMARY KEY,
  parent_id INTEGER REFERENCES categories(id),
  name VARCHAR(255),
  category_type VARCHAR(20),
  sort_order INTEGER
);
```

**Recursive Query** ашигласан:
```ruby
# Бүх дэд ангиллыг татах
def descendant_ids
  result = [id]
  visited = Set.new([id])
  queue = children.pluck(:id)
  
  while queue.any?
    current_id = queue.shift
    next if visited.include?(current_id)
    
    result << current_id
    visited << current_id
    
    child_ids = Category.where(parent_id: current_id).pluck(:id)
    queue.concat(child_ids)
  end
  
  result
end
```

**Category Tree Example**:
```
Electronics (id: 1, parent_id: nil)
  ├─ Laptops (id: 2, parent_id: 1)
  │   ├─ Gaming Laptops (id: 3, parent_id: 2)
  │   └─ Business Laptops (id: 4, parent_id: 2)
  └─ Phones (id: 5, parent_id: 1)
      ├─ Smartphones (id: 6, parent_id: 5)
      └─ Feature Phones (id: 7, parent_id: 5)
```

### 3.4 Inventory Management Design

Variant-level inventory tracking:

```
Product → Sellable → SellableVariant → Inventory
                         ↓
                    Cart/Order Items
```

**Concurrency Control**: Optimistic locking ашигласан
```ruby
class Inventory < ApplicationRecord
  # lock_version column for optimistic locking
  belongs_to :sellable_variant
  
  validates :quantity, numericality: { greater_than_or_equal_to: 0 }
  
  def decrement_quantity!(amount)
    with_lock do
      raise InsufficientStock if quantity < amount
      update!(quantity: quantity - amount)
    end
  end
  
  def increment_quantity!(amount)
    with_lock do
      update!(quantity: quantity + amount)
    end
  end
end
```

**Race Condition Prevention**:
- Database transactions
- Row-level locking
- Optimistic locking (lock_version)

### 3.5 Order Data Model

**Order Lifecycle**:
```
pending → paid → shipped → delivered
   ↓
cancelled
```

**Price Snapshot Design**:
```ruby
# OrderItem stores snapshot at order time
class OrderItem < ApplicationRecord
  belongs_to :order
  belongs_to :sellable_variant
  
  # Snapshot fields
  # - item_name (snapshot of product name)
  # - unit_price (snapshot of price at order time)
  # - quantity
  # - total_price
end
```

**Шалтгаан**: Үнэ өөрчлөгдсөн ч захиалгын түүх буруу гарахгүй

---

## 4. API ДИЗАЙН

### 4.1 RESTful API Principles

REST (Representational State Transfer) зарчмуудыг дагасан:

**Resource-oriented URLs**:
```
GET    /api/products           # Collection
GET    /api/products/:id       # Resource
POST   /api/products           # Create (admin only)
PUT    /api/products/:id       # Update (admin only)
DELETE /api/products/:id       # Delete (admin only)
```

**HTTP Verbs**:
- GET - Унших
- POST - Үүсгэх
- PUT/PATCH - Засах
- DELETE - Устгах

**Status Codes**:
- 200 OK - Амжилттай
- 201 Created - Шинэ resource үүссэн
- 400 Bad Request - Буруу параметр
- 401 Unauthorized - Нэвтрээгүй
- 403 Forbidden - Эрхгүй
- 404 Not Found - Олдсонгүй
- 422 Unprocessable Entity - Validation алдаа
- 500 Internal Server Error - Серверийн алдаа

### 4.2 JSON Response Format

**Success Response**:
```json
{
  "products": [
    {
      "id": 1,
      "name": "MacBook Pro M3",
      "base_price": 2499.99,
      "is_active": true,
      "category": {
        "id": 3,
        "name": "Gaming Laptops",
        "full_path": "Electronics > Laptops > Gaming Laptops"
      },
      "brand": {
        "id": 5,
        "name": "Apple"
      }
    }
  ],
  "meta": {
    "current_page": 1,
    "total_pages": 10,
    "total_count": 200,
    "per_page": 20
  }
}
```

**Error Response**:
```json
{
  "error": "Resource not found",
  "code": "NOT_FOUND",
  "details": {
    "resource": "Product",
    "id": 999
  }
}
```

### 4.3 API Filtering & Pagination

**Query Parameters**:
```
GET /api/products?category_id=5&min_price=100&max_price=500&q=laptop&page=2&per_page=20
```

**Implementation**:
```ruby
class Api::ProductsController < ApplicationController
  def index
    @products = Product.includes(:sellable, :category, :brand)
      .paginate(page: params[:page], per_page: params[:per_page] || 20)
    
    @products = @products.where(category_id: params[:category_id]) if params[:category_id]
    @products = @products.joins(:sellable).where('sellables.name LIKE ?', "%#{params[:q]}%") if params[:q]
    
    render json: {
      products: @products.map { |p| product_json(p) },
      meta: pagination_meta(@products)
    }
  end
end
```

### 4.4 API Versioning Strategy

Namespace-based versioning (future):
```ruby
# config/routes.rb
namespace :api do
  namespace :v1 do
    resources :products
  end
  
  namespace :v2 do
    resources :products
  end
end
```

---

## 5. АЮУЛГҮЙ БАЙДЛЫН ДИЗАЙН

### 5.1 Authentication Design

**Devise Gem** ашигласан стратеги:

```
┌──────────────┐
│   Browser    │
└──────┬───────┘
       │
       │ Email/Password
       ▼
┌──────────────┐
│    Devise    │ ── BCrypt ──┐
│  Sessions    │             │
└──────┬───────┘             ▼
       │              ┌─────────────┐
       │              │ Password    │
       │              │ Hash        │
       ▼              └─────────────┘
┌──────────────┐
│   Session    │
│   Cookie     │
└──────────────┘
```

**Security Features**:
- Password hashing (BCrypt with cost 12)
- Session management (signed cookies)
- Remember me token (secure random)
- Password reset (time-limited tokens)
- Email confirmation
- Account lockable (after 5 failed attempts)

**Implementation**:
```ruby
# app/models/user.rb
class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :confirmable, :lockable
  
  validates :email, presence: true, uniqueness: true
  validates :role, inclusion: { in: %w[customer staff admin] }
end
```

### 5.2 Authorization Design

**Pundit Gem** - Policy-based authorization:

```ruby
# app/policies/product_policy.rb
class ProductPolicy < ApplicationPolicy
  def index?
    true  # Бүгд харж болно
  end
  
  def show?
    true
  end
  
  def create?
    user.admin? || user.staff?
  end
  
  def update?
    user.admin? || (user.staff? && record.created_by == user)
  end
  
  def destroy?
    user.admin?
  end
end
```

**Role Hierarchy**:
```
Admin (Бүх эрх)
  ↓
Staff (Хязгаарлагдмал)
  ↓
Customer (Зөвхөн харах)
```

**Usage in Controller**:
```ruby
class Admin::ProductsController < Admin::BaseController
  before_action :set_product, only: [:edit, :update, :destroy]
  
  def update
    authorize @product  # Pundit эрх шалгах
    
    if @product.update(product_params)
      redirect_to admin_products_path
    else
      render :edit
    end
  end
end
```

### 5.3 CSRF & XSS Protection

**CSRF (Cross-Site Request Forgery)**:
```ruby
class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  # Authenticity token автомат шалгах
end
```

```erb
<!-- Form дээр автомат token нэмэх -->
<%= form_with model: @product do |f| %>
  <!-- Hidden authenticity token field -->
  <%= f.text_field :name %>
<% end %>
```

**XSS (Cross-Site Scripting)**:
```erb
<%# Автомат HTML escape %>
<%= product.name %>  <!-- Safe -->

<%# Raw HTML (зөвхөн admin, sanitized) %>
<%== sanitize(product.description, 
    tags: %w[p br strong em ul ol li],
    attributes: %w[href src]) %>
```

### 5.4 SQL Injection Prevention

**ActiveRecord автомат escape**:
```ruby
# ✅ Safe - Parameterized query
Product.where("name LIKE ?", "%#{params[:q]}%")

# ❌ Dangerous - String interpolation
Product.where("name LIKE '%#{params[:q]}%'")  # Don't do this!
```

### 5.5 Mass Assignment Protection

**Strong Parameters**:
```ruby
class ProductsController < ApplicationController
  private
  
  def product_params
    params.require(:product).permit(
      :category_id, :brand_id, :sku_base,
      sellable_attributes: [:name, :description, :base_price, :is_active]
    )
  end
end
```

---

## 6. ГҮЙЦЭТГЭЛИЙН ДИЗАЙН

### 6.1 Database Query Optimization

**N+1 Query Problem шийдэл**:

```ruby
# ❌ Муу - N+1 query (1 + 20 queries)
products = Product.limit(20)
products.each do |product|
  puts product.category.name      # Extra query!
  puts product.brand.name         # Extra query!
  puts product.sellable.name      # Extra query!
end

# ✅ Сайн - Eager loading (4 queries total)
products = Product.includes(:category, :brand, :sellable).limit(20)
products.each do |product|
  puts product.category.name      # No extra query
  puts product.brand.name         # No extra query
  puts product.sellable.name      # No extra query
end
```

**Index Strategy**:
```ruby
# db/migrate/xxx_add_indexes.rb
class AddIndexes < ActiveRecord::Migration[8.0]
  def change
    # Foreign key indexes
    add_index :products, :category_id
    add_index :products, :brand_id
    add_index :products, :sellable_id
    
    # Composite indexes for common queries
    add_index :order_items, [:order_id, :sellable_variant_id]
    add_index :sellable_variants, [:sellable_id, :is_active]
    
    # Search indexes
    add_index :sellables, :name
    add_index :categories, [:parent_id, :sort_order]
  end
end
```

**Query Analysis**:
```ruby
# Explain query plan
Product.includes(:category).where(category_id: 5).explain
```

### 6.2 Caching Strategy

**Multi-level caching**:

```ruby
# 1. Fragment caching - View level
<% cache ["product-card", product] do %>
  <%= render "products/card", product: product %>
<% end %>

# 2. Collection caching
<% cache ["products-list", @products.cache_key_with_version] do %>
  <%= render @products %>
<% end %>

# 3. Query result caching
def self.active_categories
  Rails.cache.fetch("categories/active", expires_in: 1.hour) do
    Category.where(is_active: true).includes(:children).to_a
  end
end

# 4. Low-level caching
def expensive_calculation
  Rails.cache.fetch("user/#{id}/stats", expires_in: 15.minutes) do
    # Complex calculation here
    orders.sum(:total_price)
  end
end
```

**Cache invalidation**:
```ruby
# Model callback
class Product < ApplicationRecord
  after_save :clear_cache
  after_destroy :clear_cache
  
  private
  
  def clear_cache
    Rails.cache.delete("products/featured")
    Rails.cache.delete(["product", id])
  end
end
```

**Solid Cache** - Database-backed cache:
- Session storage
- Fragment caching
- Query result caching
- Disk-based for development
- PostgreSQL-based for production

### 6.3 Background Job Design

**Solid Queue** ашигласан асинхрон боловсруулалт:

```ruby
# Email илгээх job
class OrderMailerJob < ApplicationJob
  queue_as :default
  
  def perform(order_id)
    order = Order.find(order_id)
    OrderMailer.confirmation(order).deliver_now
  end
end

# Image processing job
class ProductImageProcessorJob < ApplicationJob
  queue_as :low_priority
  
  def perform(product_id)
    product = Product.find(product_id)
    # Process images, generate thumbnails
  end
end

# Report generation
class MonthlyReportJob < ApplicationJob
  queue_as :reports
  
  def perform(month, year)
    # Generate and email report
  end
end
```

**Queue priority**:
- `critical` - Payment processing
- `default` - User-facing operations
- `low_priority` - Image processing
- `reports` - Scheduled reports

**Usage**:
```ruby
# Immediate
OrderMailerJob.perform_now(@order.id)

# Async
OrderMailerJob.perform_later(@order.id)

# Scheduled
OrderMailerJob.set(wait: 1.hour).perform_later(@order.id)
```

### 6.4 Asset Pipeline Optimization

**Propshaft** - Modern asset pipeline:
```ruby
# config/environments/production.rb
config.assets.compile = false
config.assets.digest = true
config.public_file_server.enabled = true
```

**Tailwind CSS optimization**:
```bash
# Purge unused CSS in production
bin/rails tailwindcss:build
```

**Image optimization**:
```ruby
# Active Storage variants
class Product < ApplicationRecord
  has_one_attached :image do |attachable|
    attachable.variant :thumb, resize_to_limit: [200, 200]
    attachable.variant :medium, resize_to_limit: [500, 500]
    attachable.variant :large, resize_to_limit: [1000, 1000]
  end
end
```

---

## 7. UI/UX ДИЗАЙН

### 7.1 Design System

**Tailwind CSS** - Utility-first approach:

**Color Palette**:
```css
/* Primary colors */
bg-blue-500      /* Primary action */
bg-blue-600      /* Primary hover */

/* Status colors */
bg-green-500     /* Success */
bg-red-500       /* Error */
bg-yellow-500    /* Warning */
bg-gray-500      /* Neutral */
```

**Typography Scale**:
```html
<h1 class="text-4xl font-bold">   <!-- 36px -->
<h2 class="text-3xl font-bold">   <!-- 30px -->
<h3 class="text-2xl font-bold">   <!-- 24px -->
<p class="text-base">             <!-- 16px -->
<small class="text-sm">           <!-- 14px -->
```

**Spacing System** (4px base unit):
```
p-2  = 8px
p-4  = 16px
p-6  = 24px
p-8  = 32px
```

**Component Example**:
```html
<div class="bg-white rounded-lg shadow-md p-6 hover:shadow-lg transition">
  <h2 class="text-2xl font-bold text-gray-800">Product Name</h2>
  <p class="text-gray-600 mt-2">Description text here</p>
  <div class="flex items-center justify-between mt-4">
    <span class="text-xl font-bold text-blue-600">$99.99</span>
    <button class="bg-blue-500 hover:bg-blue-600 text-white px-4 py-2 rounded">
      Add to Cart
    </button>
  </div>
</div>
```

### 7.2 Progressive Enhancement

**Stimulus Controllers** - JavaScript зөвхөн enhance хийх:

```javascript
// product_filter_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["searchInput", "categorySelect"]
  static values = { debounceDelay: { type: Number, default: 500 } }
  
  connect() {
    this.timeout = null
  }
  
  search() {
    clearTimeout(this.timeout)
    this.timeout = setTimeout(() => {
      this.element.requestSubmit()
    }, this.debounceDelayValue)
  }
  
  submitForm() {
    this.element.requestSubmit()
  }
}
```

```html
<!-- HTML with Stimulus -->
<form data-controller="product-filter" data-action="submit->product-filter#submitForm">
  <input type="text" 
         data-product-filter-target="searchInput"
         data-action="input->product-filter#search">
  
  <select data-product-filter-target="categorySelect"
          data-action="change->product-filter#submitForm">
    <!-- Options -->
  </select>
</form>
```

**Turbo Drive**:
- Page transitions without full reload
- Progress bar indicator
- Back button support
- Automatic form submission

### 7.3 Responsive Design

**Mobile-first approach**:

```html
<!-- Breakpoints: sm(640px), md(768px), lg(1024px), xl(1280px) -->
<div class="
  grid 
  grid-cols-1       <!-- Mobile: 1 column -->
  sm:grid-cols-2    <!-- Small: 2 columns -->
  md:grid-cols-3    <!-- Medium: 3 columns -->
  lg:grid-cols-4    <!-- Large: 4 columns -->
  gap-4
">
  <!-- Product cards -->
</div>
```

**Responsive Typography**:
```html
<h1 class="text-2xl md:text-4xl lg:text-5xl font-bold">
  Responsive Heading
</h1>
```

**Mobile Navigation**:
```html
<!-- Hamburger menu on mobile, full nav on desktop -->
<nav class="md:block hidden">
  <!-- Desktop navigation -->
</nav>

<button class="md:hidden" data-action="click->sidebar#toggle">
  <!-- Mobile menu icon -->
</button>
```

### 7.4 Accessibility (A11y)

**ARIA labels**:
```html
<button aria-label="Add to cart" aria-describedby="product-price">
  <span aria-hidden="true">🛒</span>
</button>

<div id="product-price" class="sr-only">
  Price: $99.99
</div>
```

**Keyboard navigation**:
```javascript
// Escape key to close modal
document.addEventListener('keydown', (e) => {
  if (e.key === 'Escape') {
    closeModal()
  }
})
```

**Focus management**:
```css
/* Visible focus indicator */
.focus-visible:focus {
  @apply ring-2 ring-blue-500 ring-offset-2;
}
```

---

## 8. ТЕСТИЙН ДИЗАЙН

### 8.1 Test Pyramid

```
        ┌───────┐
        │  E2E  │  ← Цөөн (5%)
        └───────┘
      ┌───────────┐
      │Controller │  ← Дунд (25%)
      │   Tests   │
      └───────────┘
    ┌───────────────┐
    │  Model Tests  │  ← Их (70%)
    │Service Tests  │
    └───────────────┘
```

### 8.2 Unit Tests - Models

```ruby
# test/models/product_test.rb
class ProductTest < ActiveSupport::TestCase
  test "should not save product without sellable" do
    product = Product.new(category: categories(:electronics))
    assert_not product.save
    assert_includes product.errors[:sellable], "must exist"
  end
  
  test "category must be leaf" do
    parent = categories(:electronics)  # Has children
    product = products(:laptop)
    product.category = parent
    
    assert_not product.valid?
    assert_includes product.errors[:category], "must be a leaf category"
  end
  
  test "descendant_ids returns all descendants" do
    electronics = categories(:electronics)
    laptops = categories(:laptops)
    gaming = categories(:gaming_laptops)
    
    assert_includes electronics.descendant_ids, laptops.id
    assert_includes electronics.descendant_ids, gaming.id
  end
end
```

### 8.3 Service Tests

```ruby
# test/services/cart_to_order_service_test.rb
class CartToOrderServiceTest < ActiveSupport::TestCase
  setup do
    @user = users(:customer)
    @cart = carts(:active_cart)
    @cart.cart_items.create!(
      sellable_variant: sellable_variants(:laptop_variant),
      quantity: 2
    )
  end
  
  test "successfully creates order from cart" do
    result = CartToOrderService.call(
      cart: @cart,
      shipping_address_params: {
        city: "Ulaanbaatar",
        phone_number: "99119911"
      }
    )
    
    assert result.success?
    assert_equal 1, Order.count
    assert_equal 2, result.order.order_items.count
    assert_equal 'pending', result.order.status
  end
  
  test "fails with empty cart" do
    @cart.cart_items.destroy_all
    
    result = CartToOrderService.call(cart: @cart)
    
    assert_not result.success?
    assert_equal "Cart is empty", result.error
  end
end
```

### 8.4 Controller Tests

```ruby
# test/controllers/products_controller_test.rb
class ProductsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get products_url
    assert_response :success
    assert_select "h1", "Products"
  end
  
  test "should filter by category" do
    electronics = categories(:electronics)
    
    get products_url, params: { category_id: electronics.id }
    
    assert_response :success
    assert_select ".product-card", minimum: 1
  end
  
  test "should search products" do
    get products_url, params: { q: "laptop" }
    
    assert_response :success
    assert_select ".product-card", minimum: 1
  end
end
```

### 8.5 Integration Tests

```ruby
# test/integration/checkout_flow_test.rb
class CheckoutFlowTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:customer)
    @product = products(:laptop)
    @variant = sellable_variants(:laptop_variant)
  end
  
  test "complete checkout flow" do
    # Login
    post user_session_url, params: {
      user: { email: @user.email, password: 'password' }
    }
    assert_redirected_to root_url
    
    # Add to cart
    post cart_items_url, params: {
      cart_item: { sellable_variant_id: @variant.id, quantity: 1 }
    }
    assert_response :redirect
    
    # View cart
    get cart_url
    assert_response :success
    assert_select ".cart-item", count: 1
    
    # Checkout
    post orders_url, params: {
      shipping_address: {
        city: "Ulaanbaatar",
        phone_number: "99119911"
      }
    }
    
    assert_redirected_to order_url(Order.last)
    assert_equal 1, Order.count
    assert_equal 'pending', Order.last.status
  end
end
```

### 8.6 Test Fixtures

```yaml
# test/fixtures/products.yml
laptop:
  sellable: laptop_sellable
  category: laptops
  brand: apple
  sku_base: "MBP-M3"

# test/fixtures/sellables.yml
laptop_sellable:
  name: "MacBook Pro M3"
  description: "Powerful laptop"
  base_price: 2499.99
  sellable_type: "Product"
  is_active: true
```

---

## 9. DEPLOYMENT ДИЗАЙН

### 9.1 Environment Configuration

**12-Factor App principles**:

```yaml
# config/database.yml
production:
  url: <%= ENV['DATABASE_URL'] %>
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
  timeout: 5000
```

**Environment Variables**:
```bash
# .env (not committed)
DATABASE_URL=postgresql://user:pass@host:5432/dbname
SECRET_KEY_BASE=long_random_string
RAILS_ENV=production
RAILS_LOG_LEVEL=info
RAILS_SERVE_STATIC_FILES=true
```

### 9.2 Docker Configuration

```dockerfile
# Dockerfile
FROM ruby:3.3.0-slim

# Install dependencies
RUN apt-get update -qq && \
    apt-get install -y build-essential libpq-dev nodejs

# Set working directory
WORKDIR /app

# Install gems
COPY Gemfile Gemfile.lock ./
RUN bundle install

# Copy application
COPY . .

# Precompile assets
RUN bundle exec rails assets:precompile

# Expose port
EXPOSE 3000

# Start server
CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
```

**Docker Compose** (development):
```yaml
version: '3.8'
services:
  web:
    build: .
    ports:
      - "3000:3000"
    environment:
      - DATABASE_URL=postgresql://postgres:password@db:5432/alshop_development
    depends_on:
      - db
  
  db:
    image: postgres:16
    environment:
      - POSTGRES_PASSWORD=password
    volumes:
      - postgres_data:/var/lib/postgresql/data

volumes:
  postgres_data:
```

### 9.3 Deployment Strategy

**Railway Platform**:
```yaml
# railway.yml (optional config)
build:
  builder: DOCKERFILE
  dockerfilePath: Dockerfile

deploy:
  startCommand: bundle exec rails server -b 0.0.0.0
  healthcheckPath: /up
  healthcheckTimeout: 100
  restartPolicyType: ON_FAILURE
```

**Database Migration**:
```bash
# Automatic on deploy
bundle exec rails db:migrate
```

**Zero-Downtime Deployment**:
1. Build new container
2. Run migrations (safe migrations only)
3. Start new containers
4. Health check
5. Route traffic to new containers
6. Stop old containers

### 9.4 Monitoring & Logging

**Rails Logger**:
```ruby
# config/environments/production.rb
config.log_level = :info
config.log_tags = [:request_id]
```

**Error Tracking** (future):
- Sentry
- Rollbar
- Bugsnag

**Performance Monitoring** (future):
- New Relic
- Scout APM
- Skylight

---

## 10. ДИЗАЙНЫ ҮНЭЛГЭЭ

### 10.1 Давуу Талууд

✅ **Modular Architecture**
- Давхаргад тодорхой ангилсан
- Service layer бизнес логик тусгаарласан
- Thin controllers, fat models зарчим

✅ **SOLID Principles**
- Single responsibility баримталсан
- Код тестлэх хялбар
- Шинэ функц нэмэх хялбар

✅ **Performance**
- Eager loading - N+1 prevention
- Multi-level caching
- Database indexes
- Background jobs

✅ **Security**
- Strong authentication (Devise + BCrypt)
- Policy-based authorization (Pundit)
- CSRF, XSS protection
- SQL injection prevention
- Mass assignment protection

✅ **Scalability**
- Service objects for complex logic
- Background job processing
- Database-backed caching
- RESTful API for future mobile apps

✅ **Developer Experience**
- Rails conventions
- Clear code structure
- Comprehensive tests
- Good documentation

✅ **Modern Frontend**
- Tailwind CSS - Fast development
- Stimulus - Progressive enhancement
- Turbo - SPA-like experience without complexity
- Minimal JavaScript

### 10.2 Trade-offs (Сонголтын үнэлгээ)

⚖️ **Monolith vs Microservices**
- **Сонголт**: Монолит
- **Шалтгаан**: 
  - Хөгжүүлэлт хялбар, хурдан
  - Deployment энгийн
  - Internship project - оверэнжинеергүй
- **Trade-off**: Хэтэрхий томорвол салгах хэрэгтэй болно

⚖️ **SQLite vs PostgreSQL (Development)**
- **Сонголт**: SQLite development дээр
- **Шалтгаан**: Setup хялбар, хурдан
- **Trade-off**: Production-тай ялгаатай, migration тест хэцүү

⚖️ **Local Storage vs S3**
- **Сонголт**: Local disk storage
- **Шалтгаан**: Зардал бага, энгийн
- **Trade-off**: Масштабирах хязгаарлалттай

⚖️ **JavaScript Framework**
- **Сонголт**: Stimulus (жижиг framework)
- **Шалтгаан**: 
  - Progressive enhancement
  - Server-side rendering давуу
  - Илүү хурдан
- **Trade-off**: Complex SPA хийхэд хэцүү

⚖️ **Database-backed Queue (Solid Queue)**
- **Сонголт**: Solid Queue (Redis биш)
- **Шалтгаан**: Нэмэлт infrastructure хэрэггүй
- **Trade-off**: Redis илүү хурдан, гэхдээ хангалттай

### 10.3 Хязгаарлалтууд

⚠️ **Масштаб**
- Монолит архитектур нь хэтэрхий томорвол хүндрэлтэй
- Хэвтээ масштабирахад load balancer хэрэгтэй

⚠️ **Real-time Features**
- Solid Cable нь WebSocket дэмжсэн гэхдээ энгийн тохиолдолд л
- Complex real-time app-д ActionCable эсвэл гаднах service хэрэгтэй

⚠️ **Search**
- Basic SQL LIKE query - slow for large datasets
- Full-text search хэрэгтэй (PostgreSQL FTS эсвэл Elasticsearch)

⚠️ **File Storage**
- Local disk - server салгах боломжгүй
- Production дээр S3/CDN шилжих хэрэгтэй

### 10.4 Ирээдүйн Сайжруулалт

🔮 **Short-term (3-6 сар)**
1. **TypeScript** - Stimulus controllers type safety
2. **PostgreSQL FTS** - Full-text search
3. **Redis caching** - Faster in-memory cache
4. **S3 storage** - Cloud file storage
5. **Admin dashboard metrics** - Sales charts, analytics

🔮 **Medium-term (6-12 сар)**
1. **GraphQL API** - Flexible mobile API
2. **Elasticsearch** - Advanced search, faceted filtering
3. **Payment gateway** - Stripe/Qpay integration
4. **Email service** - SendGrid/Mailgun
5. **CDN** - CloudFlare for static assets
6. **Monitoring** - Sentry error tracking, New Relic APM

🔮 **Long-term (1-2 жил)**
1. **Microservices** - Service салгах (inventory, payments)
2. **Message queue** - RabbitMQ/Kafka for events
3. **Separate admin app** - React/Vue admin panel
4. **Mobile apps** - iOS/Android with GraphQL
5. **Machine learning** - Recommendation engine
6. **Multi-tenant** - SaaS platform

---

## 11. ДИЗАЙНЫ ЗАГВАРУУДЫН ХУРААНГУЙ

### 11.1 Ашигласан Design Patterns

#### **Architectural Patterns**
1. **MVC (Model-View-Controller)** - Rails core pattern
2. **Service Layer** - Business logic encapsulation
3. **Repository Pattern** - ActiveRecord ORM

#### **Creational Patterns**
1. **Factory Pattern** - Sellable types (Product/Service)
2. **Builder Pattern** - Complex object construction (Order from Cart)

#### **Structural Patterns**
1. **Decorator Pattern** - Active Storage variants
2. **Adapter Pattern** - External API integrations (future)
3. **Facade Pattern** - Service objects simplify complex operations

#### **Behavioral Patterns**
1. **Strategy Pattern** - PricingCalculator with different rules
2. **Observer Pattern** - Model callbacks (minimal use)
3. **Command Pattern** - Service objects as commands
4. **Template Method** - Base controllers

#### **Data Patterns**
1. **Active Record Pattern** - Rails ORM
2. **Data Mapper** - Soft implementation via Service objects
3. **Unit of Work** - Database transactions

### 11.2 Rails Conventions

```ruby
# RESTful routes
resources :products do
  resources :reviews
end

# Strong parameters
def product_params
  params.require(:product).permit(:name, :description)
end

# Scopes
scope :active, -> { where(is_active: true) }

# Callbacks (minimal)
before_validation :normalize_data
after_create :send_notification

# Validations
validates :name, presence: true, uniqueness: true
```

---

## 12. КОДЫН ЧАНАРЫН СТАНДАРТ

### 12.1 Ruby Style Guide

**Rubocop** configuration:
```yaml
# .rubocop.yml
AllCops:
  TargetRubyVersion: 3.3
  NewCops: enable

Style/StringLiterals:
  EnforcedStyle: single_quotes

Metrics/MethodLength:
  Max: 20

Metrics/ClassLength:
  Max: 150
```

### 12.2 Code Review Checklist

- [ ] Tests бичсэн эсэх
- [ ] N+1 query байхгүй
- [ ] Strong parameters ашигласан
- [ ] Authorization шалгасан
- [ ] Error handling хийсэн
- [ ] Validation бүрэн эсэх
- [ ] Comments тайлбартай эсэх
- [ ] Naming conventions зөв эсэх

### 12.3 Performance Guidelines

```ruby
# Batch operations
Product.where(category_id: category.descendant_ids).find_each do |product|
  product.update_something
end

# Bulk inserts
OrderItem.insert_all([
  { order_id: 1, product_id: 1 },
  { order_id: 1, product_id: 2 }
])

# Avoid memory bloat
Product.find_each(batch_size: 100) do |product|
  # Process one by one
end
```

---

## ДҮГНЭЛТ

AlShop системийн дизайн нь **орчин үеийн web development best practices**-ийг дагасан, **maintainable**, **scalable**, **secure** e-commerce платформ юм. 

**Гол ололтууд**:
- ✅ MVC + Service Layer архитектур - тодорхой, засварлах хялбар
- ✅ SOLID зарчмууд - уян хатан, тестлэх боломжтой
- ✅ Polymorphic design - код давтагдахгүй (DRY)
- ✅ RESTful API - стандарт, ойлгомжтой
- ✅ Security-first - authentication, authorization, protection
- ✅ Performance optimization - caching, indexing, background jobs
- ✅ Modern frontend - Tailwind, Stimulus, Turbo
- ✅ Developer-friendly - Rails conventions, clear structure

**Технологийн stack**:
- Ruby on Rails 8.1 - Backend framework
- PostgreSQL/SQLite3 - Database
- Tailwind CSS - Frontend styling
- Stimulus - JavaScript enhancement
- Hotwire Turbo - Fast navigation
- Devise - Authentication
- Pundit - Authorization
- Solid trio - Cache, Queue, Cable

**Ашигласан дизайн загварууд**:
- MVC + Service Layer Architecture
- Polymorphic Association Pattern
- RESTful API Design
- Policy-based Authorization
- Strategy Pattern (Pricing)
- Factory Pattern (Sellable types)
- Repository Pattern (ActiveRecord)
- Command Pattern (Service objects)

Энэхүү дизайн нь internship project-ийн хүрээнд **production-ready** платформ бүтээхэд тохиромжтой, ирээдүйд **өргөтгөх**, **масштабирах** боломжтой архитектур юм.

---

**Документ хувилбар**: 1.0  
**Огноо**: 2026-02-04  
**Төсөл**: AlShop E-Commerce Platform  
**Бэлтгэсэн**: Development Team  
**Статус**: ✅ Баталсан
