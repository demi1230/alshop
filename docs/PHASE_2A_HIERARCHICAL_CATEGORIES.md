# Phase 2A: Hierarchical Category Filtering

## Overview

Implemented hierarchical category filtering using self-referential ActiveRecord associations. This demonstrates understanding of:
- Self-referential model relationships
- Recursive tree traversal
- Complex filtering with scopes
- Dependent dropdowns with Stimulus

## Category Hierarchy Structure

Categories support unlimited nesting using a self-referential `parent_id` foreign key:

```
Electronics (root)
├── Computers
│   ├── Laptops
│   ├── Desktops
│   └── Peripherals
├── Mobile Devices
│   ├── Smartphones
│   └── Tablets
└── Audio & Video
    ├── Headphones
    └── Speakers
```

## Database Schema

```ruby
# app/models/category.rb
class Category < ApplicationRecord
  belongs_to :parent, class_name: 'Category', optional: true
  has_many :children, class_name: 'Category', foreign_key: 'parent_id'
  has_many :products
  
  # Scopes
  scope :roots, -> { where(parent_id: nil) }
  scope :ordered, -> { order(:name) }
  
  # Returns array of all descendant IDs (self + children + grandchildren + ...)
  def descendant_ids
    ids = [id]
    children.each { |child| ids += child.descendant_ids }
    ids
  end
  
  # Returns full category path: "Electronics > Computers > Laptops"
  def full_path
    parent ? "#{parent.full_path} > #{name}" : name
  end
end
```

**Migration:**
```ruby
create_table :categories do |t|
  t.string :name, null: false
  t.references :parent, foreign_key: { to_table: :categories }
  t.text :description
  t.timestamps
end

add_index :categories, :parent_id
```

## Filtering Logic

### Product Scopes

```ruby
# app/models/product.rb
scope :in_category, ->(cat_id) {
  where(category_id: cat_id) if cat_id.present?
}

scope :in_category_tree, ->(parent_cat_id) {
  if parent_cat_id.present?
    category = Category.find_by(id: parent_cat_id)
    where(category_id: category.descendant_ids) if category
  end
}
```

**Usage:**
```ruby
# Get all products in Electronics and ALL sub-categories
Product.in_category_tree(electronics_id)  # Returns products in Computers, Mobile, Audio, etc.

# Get products only in Laptops category (exact match)
Product.in_category(laptops_id)
```

### Controller Logic

```ruby
# app/controllers/products_controller.rb
def index
  @products = policy_scope(Product).includes(:category, :brand, :sellable)
  
  # Hierarchical filtering
  if params[:parent_category_id].present?
    # Filter by parent + all descendants
    @products = @products.in_category_tree(params[:parent_category_id])
    
    # Optional: Further filter by specific sub-category
    if params[:category_id].present?
      @products = @products.in_category(params[:category_id])
    end
  elsif params[:category_id].present?
    # Direct category filter
    @products = @products.in_category(params[:category_id])
  end
  
  # Load sub-categories for dependent dropdown
  if params[:parent_category_id].present?
    parent = Category.find_by(id: params[:parent_category_id])
    @sub_categories = parent.children.ordered if parent
  end
  
  @products = @products.recent.paginate(page: params[:page], per_page: 20)
end

private

def set_categories
  @parent_categories = Category.roots.ordered  # Only top-level categories
end
```

## URL Parameter Patterns

```
# Show all products
GET /products

# Filter by parent category (includes all sub-categories)
GET /products?parent_category_id=1
# Example: parent_category_id=1 (Electronics)
# → Shows products in Computers, Mobile, Audio, Gaming, etc.

# Filter by parent + specific sub-category
GET /products?parent_category_id=1&category_id=9
# Example: parent_category_id=1 (Electronics) + category_id=9 (Computers)
# → Shows products only in Laptops, Desktops, Peripherals

# Direct category filter (no parent)
GET /products?category_id=23
# Example: category_id=23 (Laptops)
# → Shows products only in Laptops
```

## Frontend: Dependent Dropdowns

### View (ERB)

```erb
<%= form_with url: products_path, method: :get, 
  data: { controller: "category-filter product-filter" } do |f| %>
  
  <!-- Parent Category Dropdown -->
  <div>
    <%= f.label :parent_category_id, "Category" %>
    <%= f.select :parent_category_id,
      options_for_select(
        [["All Categories", ""]] + @parent_categories.map { |c| [c.name, c.id] },
        @current_parent_category_id
      ),
      {},
      data: { 
        action: "change->category-filter#loadSubCategories change->product-filter#submitForm",
        category_filter_target: "parentSelect"
      }
    %>
  </div>
  
  <!-- Sub-Category Dropdown (dependent) -->
  <div data-category-filter-target="subCategoryContainer">
    <%= f.label :category_id, "Sub-Category" %>
    <%= f.select :category_id,
      options_for_select(
        [["All Sub-Categories", ""]] + (@sub_categories&.map { |c| [c.name, c.id] } || []),
        @current_category_id
      ),
      {},
      data: { 
        action: "change->product-filter#submitForm",
        category_filter_target: "subCategorySelect"
      },
      disabled: @sub_categories.blank?
    %>
  </div>
<% end %>
```

### Stimulus Controller

```javascript
// app/javascript/controllers/category_filter_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["parentSelect", "subCategorySelect"]

  connect() {
    this.updateSubCategoryState()
  }

  loadSubCategories(event) {
    const parentId = this.parentSelectTarget.value
    
    if (!parentId) {
      this.subCategorySelectTarget.innerHTML = '<option value="">All Sub-Categories</option>'
      this.subCategorySelectTarget.disabled = true
      return
    }

    // Fetch sub-categories via AJAX
    fetch(`/categories/${parentId}/children.json`)
      .then(response => response.json())
      .then(data => {
        this.subCategorySelectTarget.innerHTML = '<option value="">All Sub-Categories</option>'
        
        data.forEach(category => {
          const option = document.createElement('option')
          option.value = category.id
          option.textContent = category.name
          this.subCategorySelectTarget.appendChild(option)
        })
        
        this.subCategorySelectTarget.disabled = false
      })
  }

  updateSubCategoryState() {
    const parentId = this.parentSelectTarget.value
    if (!parentId) {
      this.subCategorySelectTarget.disabled = true
    }
  }
}
```

### AJAX Endpoint

```ruby
# app/controllers/categories_controller.rb
class CategoriesController < ApplicationController
  def children
    category = Category.find(params[:id])
    render json: category.children.ordered.map { |c| { id: c.id, name: c.name } }
  rescue ActiveRecord::RecordNotFound
    render json: [], status: :not_found
  end
end
```

**Route:**
```ruby
resources :categories, only: [] do
  member do
    get :children, defaults: { format: :json }
  end
end
```

## Entity Relationship Diagram (ERD)

```
┌─────────────────────┐
│     categories      │
├─────────────────────┤
│ id (PK)             │
│ name                │
│ parent_id (FK) ────┐
│ description         │
│ created_at          │
│ updated_at          │
└─────────────────────┘
          │           │
          │ Self-     │
          │ Reference │
          └───────────┘

         1:N           1:N
          │             │
          └─────────────┘
                 │
                 ▼
        ┌─────────────────────┐
        │      products       │
        ├─────────────────────┤
        │ id (PK)             │
        │ sellable_id (FK)    │
        │ category_id (FK) ───┘
        │ brand_id (FK)       │
        │ sku_base            │
        │ created_at          │
        │ updated_at          │
        └─────────────────────┘
```

**Relationship Rules:**
- A category can have **many children** (sub-categories)
- A category can have **one parent** (or none if it's a root)
- A product **belongs to one leaf category** (deepest level)
- Parent categories should NOT have direct products assigned

## Trade-offs & Design Decisions

### 1. Recursive Ruby Method vs SQL CTE

**Decision:** Use recursive Ruby method (`descendant_ids`)

**Pros:**
- Simpler to understand and maintain
- No database-specific SQL (portable across PostgreSQL, MySQL, SQLite)
- Works well for shallow hierarchies (3-5 levels)

**Cons:**
- Not efficient for deep hierarchies (10+ levels)
- N+1 queries if not careful
- Does not scale to thousands of categories

**When to use SQL CTE instead:**
```ruby
# PostgreSQL WITH RECURSIVE query (for deep hierarchies)
scope :in_category_tree, ->(parent_cat_id) {
  if parent_cat_id.present?
    sql = <<-SQL
      WITH RECURSIVE category_tree AS (
        SELECT id FROM categories WHERE id = ?
        UNION ALL
        SELECT c.id FROM categories c
        INNER JOIN category_tree ct ON c.parent_id = ct.id
      )
      SELECT id FROM category_tree
    SQL
    
    category_ids = Category.connection.execute(
      Category.sanitize_sql([sql, parent_cat_id])
    ).map { |row| row['id'] }
    
    where(category_id: category_ids)
  end
}
```

**Use SQL CTE when:**
- Deep hierarchies (10+ levels)
- Large category trees (1000+ categories)
- PostgreSQL/MySQL database
- Performance is critical

### 2. Products in Leaf vs Parent Categories

**Decision:** Products belong to **leaf categories only** (deepest level)

**Example:**
```
✅ Correct:
Product "MacBook Pro" → Laptops (leaf category)

❌ Incorrect:
Product "MacBook Pro" → Computers (parent category)
```

**Reasoning:**
- Clearer categorization (product is in most specific category)
- Easier to filter (no ambiguity about "where" product belongs)
- Easier to display breadcrumbs: "Electronics > Computers > Laptops"

**Alternative Approach:**
Allow products in any category level, then use `OR` query:
```ruby
# Find products in category OR any descendant
where(category_id: [cat.id] + cat.descendant_ids)
```

This is more flexible but adds complexity.

### 3. Server-Side vs Client-Side Filtering

**Decision:** Server-side filtering with Rails scopes

**Pros:**
- Consistent with Rails conventions
- Works without JavaScript
- Easier to test
- Handles large datasets (pagination)

**Cons:**
- Requires page reload/form submission
- Slower than pure client-side filtering

**Hybrid Approach (future enhancement):**
Use Hotwire/Turbo to replace product table without full page reload.

### 4. Two Dropdowns vs Single Dropdown

**Decision:** Two separate dropdowns (parent + sub-category)

**Alternatives:**
1. **Single dropdown with indented options:**
```erb
<select>
  <option>Electronics</option>
  <option>  └─ Computers</option>
  <option>      └─ Laptops</option>
</select>
```

2. **Cascading dropdowns (3 levels):**
```
Parent → Child → Grandchild
```

**Chosen approach rationale:**
- Clearer UX (explicit parent vs sub-category)
- Easier to implement dependent behavior
- Better for mobile (smaller dropdowns)

## Testing Strategy

### Model Tests
```ruby
# test/models/category_test.rb
test "descendant_ids returns all descendants recursively" do
  electronics = categories(:electronics)
  computers = categories(:computers)
  laptops = categories(:laptops)
  
  assert_includes electronics.descendant_ids, computers.id
  assert_includes electronics.descendant_ids, laptops.id
end

test "full_path returns breadcrumb string" do
  laptops = categories(:laptops)
  assert_equal "Electronics > Computers > Laptops", laptops.full_path
end
```

### Integration Tests
```ruby
# test/integration/hierarchical_filtering_test.rb
test "filtering by parent category shows all descendant products" do
  get products_path(parent_category_id: categories(:electronics).id)
  
  assert_response :success
  assert_select '.product-row', count: Product.in_category_tree(categories(:electronics).id).count
end

test "filtering by parent + sub-category shows only sub-category products" do
  get products_path(
    parent_category_id: categories(:electronics).id,
    category_id: categories(:computers).id
  )
  
  assert_response :success
  assert_select '.product-row', count: Product.in_category(categories(:computers).id).count
end
```

### Stimulus Tests (with Jest)
```javascript
// app/javascript/controllers/category_filter_controller.test.js
describe("CategoryFilterController", () => {
  it("disables sub-category dropdown when no parent selected", () => {
    // Test implementation
  });
  
  it("loads sub-categories via AJAX when parent changes", async () => {
    // Test implementation
  });
});
```

## Performance Considerations

1. **Eager Loading:**
   ```ruby
   @products = @products.includes(:category, :brand, :sellable)
   ```
   Prevents N+1 queries when displaying product list.

2. **Database Indexes:**
   ```ruby
   add_index :categories, :parent_id
   add_index :products, :category_id
   ```

3. **Caching (future enhancement):**
   ```ruby
   def descendant_ids
     Rails.cache.fetch("category_#{id}_descendants", expires_in: 1.hour) do
       # ... recursive logic
     end
   end
   ```

4. **Counting Products:**
   ```ruby
   # Avoid this (N+1):
   Category.roots.map { |c| [c.name, c.products.count] }
   
   # Do this instead:
   Category.roots.joins(:products).group('categories.id').count
   ```

## Future Enhancements

1. **Breadcrumb Navigation:**
   ```erb
   <nav aria-label="breadcrumb">
     <% @product.category.full_path.split(' > ').each do |name| %>
       <%= link_to name, products_path(category_id: category_id) %>
     <% end %>
   </nav>
   ```

2. **Category Facets (sidebar):**
   Display category tree with product counts.

3. **URL Slugs:**
   `/products/electronics/computers/laptops` instead of `/products?category_id=23`

4. **Closure Table Pattern:**
   Precompute all ancestor-descendant relationships in separate table for O(1) queries.

---

## Summary

This implementation demonstrates:
✅ Self-referential ActiveRecord associations  
✅ Recursive tree traversal in Ruby  
✅ Complex filtering logic with multiple scopes  
✅ Dependent dropdowns with Stimulus  
✅ RESTful API endpoint for AJAX  
✅ Proper eager loading to prevent N+1 queries  
✅ Rails best practices (thin controllers, fat models)  

**Internship Portfolio Value:**
- Shows understanding of complex database relationships
- Demonstrates ability to make architecture trade-offs
- Implements interactive UX patterns
- Follows Rails conventions
