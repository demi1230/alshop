# PRODUCT LISTING QUICK REFERENCE

## URLs

```
/                           → Products index (root)
/products                   → Products index
/products?category_id=2     → Filter by category
/products?q=laptop          → Search by name
/products?category_id=2&q=laptop&page=2  → Combined filters + pagination
/products/123               → Product detail
```

## Controller Pattern

```ruby
def index
  # 1. Start with policy scope
  @products = policy_scope(Product)
    .includes(:category, :brand, :sellable)  # N+1 prevention

  # 2. Apply filters (model scopes)
  @products = @products.in_category(params[:category_id]) if params[:category_id].present?
  @products = @products.search(params[:q]) if params[:q].present?

  # 3. Order and paginate
  @products = @products.recent.paginate(page: params[:page], per_page: 20)
  
  # 4. Store current filters
  @current_category_id = params[:category_id]
  @current_search_query = params[:q]
end
```

## Model Scopes

```ruby
# Chainable scopes
Product.active                    # Only active products
Product.in_category(2)           # Products in category 2
Product.search('laptop')         # Products matching "laptop"
Product.recent                   # Ordered by created_at DESC

# Combined
Product.active.in_category(2).search('laptop').recent
```

## View Patterns

### Category Dropdown
```erb
<%= f.select :category_id,
  options_for_select(
    [["All Categories", ""]] + @categories.map { |c| [c.name, c.id] },
    @current_category_id
  ),
  {},
  data: { action: "change->product-filter#submitForm" }
%>
```

### Search Input
```erb
<%= f.text_field :q,
  value: @current_search_query,
  placeholder: "Search...",
  data: { action: "input->product-filter#debounceSearch" }
%>
```

### Pagination
```erb
<%= will_paginate @products, per_page: 20 %>
```

## Stimulus Controller

```javascript
// Auto-submit on category change
submitForm(event) {
  this.element.requestSubmit()
}

// Debounce search (500ms)
debounceSearch(event) {
  clearTimeout(this.timeout)
  this.timeout = setTimeout(() => {
    this.element.requestSubmit()
  }, 500)
}
```

## Database Queries

```ruby
# Good (3 queries)
Product.includes(:category, :brand, :sellable)
  .in_category(1)
  .search('laptop')
  .paginate(page: 1, per_page: 20)

# Bad (N+1 queries)
Product.where(category_id: 1).each do |p|
  p.category.name  # N queries!
end
```

## Testing

```bash
# Seed data
rails db:seed

# Visit pages
http://localhost:3000/products
http://localhost:3000/products?category_id=1
http://localhost:3000/products?q=iPhone

# Test accounts
admin@alshop.com / password123       (sees all products)
customer@example.com / password123   (sees active products)
```

## Common Tasks

### Add new scope
```ruby
# app/models/product.rb
scope :by_price_range, ->(min, max) {
  joins(:sellable).where(sellables: { base_price: min..max })
}

# Usage
Product.by_price_range(100, 500)
```

### Add new filter
```ruby
# Controller
@products = @products.by_price_range(params[:min_price], params[:max_price])

# View
<%= f.number_field :min_price %>
<%= f.number_field :max_price %>
```

### Change pagination size
```ruby
# Controller
@products.paginate(page: params[:page], per_page: 50)  # Default: 30
```
