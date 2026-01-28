# AlShop Admin Panel

## Overview
Complete admin panel with Stimulus controllers for interactive features. Built with JSDoc annotations for type safety without TypeScript compilation.

## Access
- **URL**: `/admin`
- **Admin User**: admin@alshop.com (set with `admin: true` in users table)

## Stimulus Controllers

### Admin Controllers (app/javascript/controllers/admin/)

1. **sidebar_controller.js**
   - Mobile/desktop sidebar toggle
   - Collapse/expand functionality  
   - State persistence (localStorage)
   - Submenu expansion

2. **table_controller.js**
   - Row selection (single/bulk)
   - Select all checkbox with indeterminate state
   - Bulk actions (delete, activate, etc.)
   - Live search/filter

3. **form_controller.js**
   - Autosave functionality
   - Unsaved changes warning
   - Dynamic field addition/removal
   - File upload preview

4. **modal_controller.js**
   - Open/close animations
   - Remote content loading
   - Backdrop click to close
   - Escape key support

5. **toggle_controller.js**
   - Boolean field AJAX updates
   - Optimistic UI updates
   - Error handling with revert

6. **sortable_controller.js**
   - Drag-and-drop reordering
   - AJAX persistence
   - Handle-based dragging

## Routes Structure

```ruby
namespace :admin do
  root to: 'dashboard#index'
  
  # Catalog
  resources :products do
    collection do
      patch :bulk_update
      patch :reorder
    end
    member { patch :toggle_active }
  end
  
  resources :services do
    collection { patch :bulk_update }
    member { patch :toggle_active }
  end
  
  resources :categories do
    collection { patch :reorder }
  end
  
  resources :brands do
    collection { patch :bulk_update }
  end
  
  # Pricing
  resources :pricing_rules do
    member { patch :toggle_active }
  end
  
  resources :discounts do
    member { patch :toggle_active }
  end
  
  # Orders
  resources :orders, only: [:index, :show] do
    member do
      patch :mark_paid
      patch :mark_shipped
      patch :cancel
    end
  end
  
  resources :service_fulfillments do
    member do
      patch :assign
      patch :complete
    end
  end
  
  # B2B
  resources :companies do
    member { patch :toggle_active }
  end
  
  resources :company_pricing_rules
  
  # Users
  resources :users, only: [:index, :show, :edit, :update] do
    member { patch :toggle_active }
  end
  
  # Settings
  resource :settings, only: [:show, :update]
end
```

## Views Structure

```
app/views/
  layouts/
    admin.html.erb              # Admin layout with sidebar
  admin/
    dashboard/
      index.html.erb            # Dashboard with KPIs
    shared/
      _sidebar.html.erb         # Navigation sidebar
      _topbar.html.erb          # Top bar with breadcrumbs
    # Resource views to be created:
    products/
    services/
    categories/
    brands/
    pricing_rules/
    orders/
    companies/
    users/
```

## Usage Examples

### Using Stimulus Controllers in Views

#### Table with Bulk Actions
```erb
<div data-controller="admin--table">
  <!-- Bulk actions bar -->
  <div data-admin--table-target="bulkActions" class="hidden">
    <span data-count></span> selected
    <button data-action="click->admin--table#bulkAction"
            data-admin--table-action-param="activate">
      Activate
    </button>
  </div>
  
  <!-- Table -->
  <table>
    <thead>
      <tr>
        <th>
          <input type="checkbox" 
                 data-admin--table-target="selectAll"
                 data-action="change->admin--table#toggleAll">
        </th>
      </tr>
    </thead>
    <tbody>
      <tr data-admin--table-target="row">
        <td>
          <input type="checkbox" 
                 value="<%= product.id %>"
                 data-admin--table-target="checkbox"
                 data-action="change->admin--table#toggleRow">
        </td>
      </tr>
    </tbody>
  </table>
</div>
```

#### Form with Autosave
```erb
<%= form_with model: [:admin, @product],
              data: {
                controller: "admin--form",
                admin__form_autosave_value: true,
                admin__form_autosave_url_value: admin_product_path(@product)
              } do |f| %>
  <%= f.text_field :name %>
  <%= f.submit %>
<% end %>
```

#### Toggle Switch
```erb
<input type="checkbox" 
       data-controller="admin--toggle"
       data-admin--toggle-url-value="<%= admin_product_path(product) %>"
       data-admin--toggle-field-value="is_active"
       data-admin--toggle-enabled-value="<%= product.is_active %>"
       data-action="change->admin--toggle#toggle">
```

#### Sortable List
```erb
<div data-controller="admin--sortable"
     data-admin--sortable-url-value="<%= reorder_admin_categories_path %>"
     data-admin--sortable-handle-value=".drag-handle">
  <div data-admin--sortable-target="item" data-id="<%= category.id %>">
    <span class="drag-handle">☰</span>
    <%= category.name %>
  </div>
</div>
```

## AdminHelper Methods

- `nav_link(text, path, icon:)` - Active sidebar links
- `heroicon(name, class:)` - Heroicons SVG
- `status_badge(status, text)` - Colored status badges
- `format_currency(amount)` - Mongolian Tugrik formatting
- `format_percentage(value)` - Percentage display
- `admin_page_title(title)` - Page header

## Dashboard Features

- Revenue statistics (current vs previous month)
- Order counts and growth metrics
- Product inventory alerts (low stock, out of stock)
- Customer growth tracking
- Recent orders table
- Top selling products
- Low stock alerts
- Revenue chart data (ready for charts.js)

## Next Steps

1. **Create Product Admin**
   - Index with table_controller
   - Form with image uploads
   - Variant management
   - Stock tracking

2. **Create Category Admin**
   - Tree structure with sortable
   - Parent-child relationships
   - Drag-and-drop reordering

3. **Create Orders Admin**
   - Order list with filters
   - Order detail view
   - Status updates
   - Payment/shipping actions

4. **Add Charts**
   - Revenue charts (Chart.js)
   - Sales trends
   - Popular products

5. **Add Search**
   - Global admin search
   - Quick navigation

## Technical Notes

- **No TypeScript compilation needed** - JSDoc provides type hints
- **Importmap compatible** - All controllers use native ES modules
- **Stimulus auto-loading** - Controllers automatically discovered
- **Tailwind CSS** - Styled with Tailwind v4
- **Mobile responsive** - Sidebar adapts to mobile
- **State persistence** - Sidebar state saved to localStorage

## Security

- Authentication via Devise (`authenticate_user!`)
- Authorization via `ensure_admin!` in BaseController
- Admin boolean field on User model
- CSRF protection on all forms
- Admin role check: `current_user.admin?`
