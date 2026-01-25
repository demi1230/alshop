# AUTHENTICATION & AUTHORIZATION QUICK REFERENCE

## Test Accounts

```
Admin:    admin@alshop.com / password123
Customer: customer@example.com / password123  
Staff:    staff@alshop.com / password123
```

## Common Controller Patterns

### Require Login
```ruby
before_action :authenticate_user!
```

### Authorize Resource
```ruby
authorize @order  # Uses OrderPolicy#action_name?
authorize @product, :create?  # Explicit action
```

### Filter Collection by Policy
```ruby
@orders = policy_scope(Order)  # Uses OrderPolicy::Scope
```

### Admin-Only Controller
```ruby
class Admin::BaseController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_admin
  
  private
  
  def authorize_admin
    authorize :admin, :access?
  end
end
```

## Policy Patterns

### Basic Policy Methods
```ruby
class ProductPolicy < ApplicationPolicy
  def show?
    true  # Anyone can view
  end
  
  def create?
    user&.admin?  # Only admins
  end
  
  def update?
    user&.admin? || record.user_id == user.id  # Owner or admin
  end
end
```

### Scope Pattern
```ruby
class Scope < ApplicationPolicy::Scope
  def resolve
    if user&.admin?
      scope.all
    else
      scope.active  # Filtered for non-admins
    end
  end
end
```

## User Role Checks

```ruby
current_user.admin?    # => true/false
current_user.customer? # => true/false
current_user.staff?    # => true/false
```

## Flash Messages

```ruby
redirect_to @order, notice: 'Success message'
redirect_to @order, alert: 'Error message'
```

## Devise Helpers

```ruby
current_user          # Current logged-in user
user_signed_in?       # Check if user is logged in
authenticate_user!    # Redirect to login if not authenticated
```

## Common Routes

```
GET    /users/sign_in       - Login page
POST   /users/sign_in       - Login action
DELETE /users/sign_out      - Logout
GET    /users/sign_up       - Registration
POST   /users              - Create account
GET    /users/password/new - Forgot password
```
