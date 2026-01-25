# PHASE 1B: AUTHENTICATION + AUTHORIZATION ✅
**Devise + Pundit | Rails Best Practices**
**Completed: January 19, 2026**

---

## IMPLEMENTATION SUMMARY

Successfully implemented authentication (Devise) and authorization (Pundit) following Rails conventions.

---

## STEP-BY-STEP IMPLEMENTATION

### 1. Added Gems (Rails Convention)

```ruby
# Gemfile
gem "devise", "~> 4.9"    # Standard Rails authentication
gem "pundit", "~> 2.3"    # Standard Rails authorization
```

**Why:** Devise and Pundit are the Rails community standards for auth. No need to reinvent the wheel.

**Commands:**
```bash
bundle install
```

---

### 2. Installed & Configured Devise

**Generated Devise files:**
```bash
rails generate devise:install
```

**Created files:**
- `config/initializers/devise.rb` - Devise configuration
- `config/locales/devise.en.yml` - Devise translations

**Added Devise to User model:**
```ruby
# app/models/user.rb
class User < ApplicationRecord
  # Devise modules - standard Rails authentication
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # Role enum with default
  enum :role, { customer: 'customer', staff: 'staff', admin: 'admin' }, 
       validate: true, default: 'customer'

  # Role helper methods
  def admin?
    role == 'admin'
  end

  def customer?
    role == 'customer'
  end

  def staff?
    role == 'staff'
  end

  # Ensure user has cart after creation
  after_create :create_cart_if_needed

  private

  def create_cart_if_needed
    create_cart!(status: :active) unless cart.present?
  end
end
```

**Why these Devise modules:**
- `:database_authenticatable` - Standard email/password login
- `:registerable` - Users can sign up
- `:recoverable` - Forgot password functionality
- `:rememberable` - "Remember me" checkbox
- `:validatable` - Email/password validations

**Migration:**
```ruby
# db/migrate/..._add_devise_to_users.rb
class AddDeviseToUsers < ActiveRecord::Migration[8.1]
  def change
    # Remove has_secure_password column
    remove_column :users, :password_digest, :string

    # Add Devise columns
    add_column :users, :encrypted_password, :string, null: false, default: ""
    add_column :users, :reset_password_token, :string
    add_column :users, :reset_password_sent_at, :datetime
    add_column :users, :remember_created_at, :datetime

    add_index :users, :reset_password_token, unique: true
  end
end
```

**Routes:**
```ruby
# config/routes.rb
Rails.application.routes.draw do
  devise_for :users  # Standard Devise routes
  # ...
end
```

**Devise routes created:**
- `GET  /users/sign_in`  - Login page
- `POST /users/sign_in`  - Login action
- `DELETE /users/sign_out` - Logout
- `GET  /users/sign_up`  - Registration page
- `POST /users`  - Registration action
- `GET  /users/password/new` - Forgot password
- And more...

---

### 3. Installed & Configured Pundit

**Generated Pundit:**
```bash
rails generate pundit:install
```

**Created:**
- `app/policies/application_policy.rb` - Base policy

**Added to ApplicationController:**
```ruby
# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  # Pundit authorization
  include Pundit::Authorization

  # Handle authorization errors
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  # Strong parameters for Devise
  before_action :configure_permitted_parameters, if: :devise_controller?

  private

  def user_not_authorized
    flash[:alert] = "You are not authorized to perform this action."
    redirect_back(fallback_location: root_path)
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:email])
    devise_parameter_sanitizer.permit(:account_update, keys: [:email])
  end
end
```

**Why:**
- `include Pundit::Authorization` - Adds `authorize` and `policy_scope` methods
- `rescue_from` - Handles unauthorized access gracefully
- `configure_permitted_parameters` - Rails strong parameters for Devise

---

### 4. Created Policies (Rails Authorization Pattern)

#### A. OrderPolicy

```ruby
# app/policies/order_policy.rb
class OrderPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.admin?
        scope.all  # Admins see all orders
      else
        scope.where(user: user)  # Customers see only their orders
      end
    end
  end

  def show?
    user.admin? || record.user_id == user.id
  end

  def create?
    user.present?
  end

  def update?
    user.admin?  # Only admins can update orders
  end

  def cancel?
    return false unless record.can_be_cancelled?
    user.admin? || record.user_id == user.id
  end

  def mark_as_paid?
    user.admin?
  end

  def refund?
    user.admin?
  end
end
```

**Policy Rules:**
- Users can only see their own orders
- Admins see all orders
- Users can cancel their own pending orders
- Only admins can mark paid/shipped/refund

---

#### B. ProductPolicy

```ruby
# app/policies/product_policy.rb
class ProductPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      if user&.admin?
        scope.all  # Admins see all products
      else
        scope.active  # Public sees only active products
      end
    end
  end

  def index?
    true  # Anyone can browse products
  end

  def show?
    true  # Anyone can view a product
  end

  def create?
    user&.admin?  # Only admins can create
  end

  def update?
    user&.admin?  # Only admins can update
  end

  def destroy?
    user&.admin?  # Only admins can delete
  end
end
```

**Policy Rules:**
- Everyone can view active products
- Only admins can create/update/delete products
- Guests don't see inactive products

---

#### C. AdminPolicy

```ruby
# app/policies/admin_policy.rb
class AdminPolicy < ApplicationPolicy
  def access?
    user&.admin?
  end

  def dashboard?
    access?
  end

  def manage_products?
    access?
  end

  def manage_orders?
    access?
  end

  def view_reports?
    access?
  end
end
```

**Usage in admin controllers:**
```ruby
# Admin::BaseController
class Admin::BaseController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_admin

  private

  def authorize_admin
    authorize :admin, :access?
  end
end
```

---

### 5. Updated Layout for Flash Messages

```erb
<!-- app/views/layouts/application.html.erb -->
<body>
  <%# Flash messages for Devise and notifications %>
  <% if notice.present? || alert.present? %>
    <div class="fixed top-4 right-4 z-50 space-y-2">
      <% if notice.present? %>
        <div class="bg-green-500 text-white px-6 py-3 rounded shadow-lg">
          <%= notice %>
        </div>
      <% end %>
      <% if alert.present? %>
        <div class="bg-red-500 text-white px-6 py-3 rounded shadow-lg">
          <%= alert %>
        </div>
      <% end %>
    </div>
  <% end %>

  <main class="container mx-auto mt-28 px-5 flex">
    <%= yield %>
  </main>
</body>
```

**Why:** 
- Devise uses `notice` and `alert` flash messages
- Tailwind CSS for styling (already in project)
- Fixed positioning so messages don't break layout

---

### 6. Created Seed Data

```ruby
# db/seeds.rb
# Admin user
admin = User.find_or_create_by!(email: 'admin@alshop.com') do |user|
  user.password = 'password123'
  user.password_confirmation = 'password123'
  user.role = 'admin'
end

# Customer user
customer = User.find_or_create_by!(email: 'customer@example.com') do |user|
  user.password = 'password123'
  user.password_confirmation = 'password123'
  user.role = 'customer'
end

# Staff user
staff = User.find_or_create_by!(email: 'staff@alshop.com') do |user|
  user.password = 'password123'
  user.password_confirmation = 'password123'
  user.role = 'staff'
end
```

**Run seeds:**
```bash
rails db:seed
```

**Test accounts:**
- Admin: `admin@alshop.com` / `password123`
- Customer: `customer@example.com` / `password123`
- Staff: `staff@alshop.com` / `password123`

---

## HOW TO USE IN CONTROLLERS

### Example: ProductsController

```ruby
class ProductsController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show]
  before_action :set_product, only: [:show, :edit, :update, :destroy]

  # GET /products
  def index
    @products = policy_scope(Product)  # Uses ProductPolicy::Scope
    # Returns Product.active for guests/customers
    # Returns Product.all for admins
  end

  # GET /products/:id
  def show
    authorize @product  # Uses ProductPolicy#show?
    # Always returns true (anyone can view)
  end

  # GET /products/new
  def new
    @product = Product.new
    authorize @product  # Uses ProductPolicy#create?
    # Only admins can access
  end

  # POST /products
  def create
    @product = Product.new(product_params)
    authorize @product  # Uses ProductPolicy#create?

    if @product.save
      redirect_to @product, notice: 'Product created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def set_product
    @product = Product.find(params[:id])
  end

  def product_params
    params.require(:product).permit(:name, :description, :price, ...)
  end
end
```

**Key methods:**
- `authenticate_user!` - Devise helper, redirects to login if not authenticated
- `authorize @product` - Pundit helper, raises error if not authorized
- `policy_scope(Product)` - Pundit helper, filters collection based on policy

---

### Example: OrdersController

```ruby
class OrdersController < ApplicationController
  before_action :authenticate_user!  # All actions require login
  before_action :set_order, only: [:show, :cancel]

  # GET /orders
  def index
    @orders = policy_scope(Order)  # Uses OrderPolicy::Scope
    # Returns user's orders for customers
    # Returns all orders for admins
  end

  # GET /orders/:id
  def show
    authorize @order  # Uses OrderPolicy#show?
    # Checks: admin? || order.user_id == current_user.id
  end

  # POST /orders/:id/cancel
  def cancel
    authorize @order, :cancel?  # Uses OrderPolicy#cancel?

    if @order.cancel!(reason: params[:reason])
      redirect_to @order, notice: 'Order cancelled.'
    else
      redirect_to @order, alert: 'Cannot cancel order.'
    end
  end

  private

  def set_order
    @order = Order.find(params[:id])
  end
end
```

---

### Example: Admin::OrdersController

```ruby
class Admin::OrdersController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_admin
  before_action :set_order, only: [:show, :mark_paid, :mark_shipped]

  # GET /admin/orders
  def index
    @orders = Order.includes(:user).recent.page(params[:page])
  end

  # POST /admin/orders/:id/mark_paid
  def mark_paid
    authorize @order, :mark_as_paid?  # Uses OrderPolicy#mark_as_paid?

    if @order.mark_as_paid!(
      payment_method: params[:payment_method],
      transaction_id: params[:transaction_id]
    )
      redirect_to admin_order_path(@order), notice: 'Order marked as paid.'
    else
      redirect_to admin_order_path(@order), alert: 'Error marking order as paid.'
    end
  end

  private

  def set_order
    @order = Order.find(params[:id])
  end

  def authorize_admin
    authorize :admin, :access?  # Uses AdminPolicy#access?
  end
end
```

---

## RAILS CONVENTIONS FOLLOWED

### 1. **Thin Controllers**
Controllers only handle HTTP logic:
- Authentication checks (`authenticate_user!`)
- Authorization checks (`authorize @resource`)
- Parameter sanitization (`product_params`)
- Redirects and renders

Business logic stays in models:
```ruby
# Controller (thin)
def mark_paid
  authorize @order
  @order.mark_as_paid!(payment_method: params[:payment_method])
  redirect_to @order, notice: 'Paid.'
end

# Model (business logic)
class Order
  def mark_as_paid!(payment_method:, transaction_id:)
    transaction do
      update!(status: :paid, metadata: {...})
      create_fulfillments_if_needed
    end
  end
end
```

---

### 2. **Policy Objects (Pundit Pattern)**
Authorization logic lives in policy objects, not controllers:

```ruby
# BAD (logic in controller)
def show
  if current_user.admin? || @order.user_id == current_user.id
    # show order
  else
    redirect_to root_path, alert: 'Not authorized'
  end
end

# GOOD (policy object)
def show
  authorize @order  # Checks OrderPolicy#show?
end
```

---

### 3. **Role-Based Access Control (Enum)**
Roles stored as enum in database:

```ruby
# User model
enum :role, { customer: 'customer', staff: 'staff', admin: 'admin' }

# Helper methods
def admin?
  role == 'admin'
end

# Usage in policies
def update?
  user.admin?
end
```

**Why enum over boolean flags:**
- Scalable (easy to add new roles)
- Single source of truth
- Database-level validation
- Clear intent

---

### 4. **Scopes for Authorization**
Use `policy_scope` to filter collections:

```ruby
# Controller
def index
  @products = policy_scope(Product)
end

# Policy
class ProductPolicy
  class Scope
    def resolve
      user&.admin? ? scope.all : scope.active
    end
  end
end
```

**Why:**
- Centralizes filtering logic
- Prevents data leaks
- DRY (Don't Repeat Yourself)

---

### 5. **Callbacks for Side Effects**
User gets cart automatically after signup:

```ruby
class User < ApplicationRecord
  after_create :create_cart_if_needed

  private

  def create_cart_if_needed
    create_cart!(status: :active) unless cart.present?
  end
end
```

**Why:** Callbacks are okay for simple, direct side effects tied to record lifecycle.

---

## TESTING THE IMPLEMENTATION

### Manual Testing

**1. Sign up as customer:**
```
Visit: http://localhost:3000/users/sign_up
Email: newcustomer@test.com
Password: password123
```

**2. Login as admin:**
```
Visit: http://localhost:3000/users/sign_in
Email: admin@alshop.com
Password: password123
```

**3. Test authorization in console:**
```ruby
rails console

# Create test data
admin = User.find_by(email: 'admin@alshop.com')
customer = User.find_by(email: 'customer@example.com')

# Test policies
OrderPolicy.new(admin, order).show?     # => true
OrderPolicy.new(customer, order).show?  # => true (if order.user == customer)
OrderPolicy.new(customer, order).mark_as_paid?  # => false

ProductPolicy.new(admin, product).create?    # => true
ProductPolicy.new(customer, product).create? # => false
```

---

## FILES CREATED/MODIFIED

**Created:**
- `config/initializers/devise.rb` - Devise configuration
- `config/locales/devise.en.yml` - Devise translations
- `app/policies/application_policy.rb` - Base policy
- `app/policies/order_policy.rb` - Order authorization
- `app/policies/product_policy.rb` - Product authorization
- `app/policies/admin_policy.rb` - Admin namespace authorization
- `db/migrate/..._add_devise_to_users.rb` - Devise columns

**Modified:**
- `Gemfile` - Added devise and pundit gems
- `app/models/user.rb` - Added Devise modules, role helpers, cart callback
- `app/controllers/application_controller.rb` - Added Pundit, Devise config
- `config/routes.rb` - Added `devise_for :users`
- `app/views/layouts/application.html.erb` - Added flash messages
- `db/seeds.rb` - Added test users

---

## NEXT STEPS (PHASE 2: Customer Flow)

Now that authentication/authorization is complete, next phase:

1. **Create ProductsController** (index, show with authorization)
2. **Create CartsController** (add to cart, view cart, update quantities)
3. **Create OrdersController** (checkout, place order, view orders)
4. **Create ERB views** with Tailwind CSS
5. **Add navigation** (header with login/logout, cart icon)

---

## SUCCESS CRITERIA MET ✅

**Authentication:**
- ✅ Devise installed and configured
- ✅ User model has Devise modules
- ✅ Login/logout/signup routes working
- ✅ Role enum (admin, customer, staff)
- ✅ Role helper methods (admin?, customer?)
- ✅ Cart auto-created after signup

**Authorization:**
- ✅ Pundit installed and configured
- ✅ ApplicationPolicy base class
- ✅ OrderPolicy (users see own orders, admins see all)
- ✅ ProductPolicy (everyone views, admins manage)
- ✅ AdminPolicy (admin namespace protection)
- ✅ Policy scopes for filtering collections

**Rails Best Practices:**
- ✅ Thin controllers (only HTTP logic)
- ✅ Business logic in models
- ✅ Authorization logic in policies
- ✅ Standard Rails patterns (no over-engineering)
- ✅ Proper flash messages
- ✅ Seed data for testing

**Code Quality:**
- ✅ Clear, readable code
- ✅ Follows Rails conventions
- ✅ Easy to understand
- ✅ Interview-ready

---

## SUMMARY

PHASE 1B is **COMPLETE**. The application now has:

1. **Authentication** via Devise (industry standard)
2. **Authorization** via Pundit (Rails best practice)
3. **Role-based access** (admin, customer, staff)
4. **Thin controllers** (business logic in models)
5. **Policy objects** (authorization rules centralized)
6. **Test accounts** for development

The architecture remains simple and Rails-idiomatic, perfect for an internship portfolio demonstrating Rails competency.

**Ready for PHASE 2:** Building customer-facing controllers and views.
