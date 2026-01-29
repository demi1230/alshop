# AlShop API Guide

Complete reference for all API endpoints, services, and integration patterns.

## 📡 API Overview

AlShop provides RESTful JSON APIs for:
- Product browsing and search
- Category navigation
- Cart management
- Order creation
- Service management

## 🔌 Base URL

```
Development: http://localhost:3000/api
Production: https://alshop.railway.app/api
```

## 🔐 Authentication

### Public Endpoints
No authentication required for:
- Product listing and search
- Product detail
- Category browsing
- Service listing

### Protected Endpoints
Authentication required for:
- Cart operations
- Order creation
- Order history
- User profile

**How to Authenticate:**

1. **Session-based (Web browsers)**
   - Handled automatically by Rails session cookies
   - User logs in via `/users/sign_in`
   - Session cookie included in all subsequent requests

2. **API Token Authentication (Mobile/External)**
   - Coming in future releases
   - Will support API keys for programmatic access

## 📚 Endpoint Reference

### Products

#### List Products

```http
GET /api/products
```

**Parameters:**

| Parameter | Type | Description |
|-----------|------|-------------|
| `q` | string | Search query (product name) |
| `category_id` | integer | Filter by category ID |
| `brand_id` | integer | Filter by brand ID |
| `min_price` | decimal | Minimum price filter |
| `max_price` | decimal | Maximum price filter |
| `sort` | string | Sort order: `price_asc`, `price_desc`, `name_asc`, `name_desc` |
| `page` | integer | Page number (default: 1) |
| `per_page` | integer | Results per page (default: 20) |

**Example Requests:**

```bash
# Get all products
curl http://localhost:3000/api/products

# Search products
curl "http://localhost:3000/api/products?q=laptop"

# Filter by category and price
curl "http://localhost:3000/api/products?category_id=5&min_price=100000&max_price=500000"

# Sort and paginate
curl "http://localhost:3000/api/products?sort=price_asc&page=2&per_page=50"
```

**Response (200 OK):**

```json
{
  "products": [
    {
      "id": 1,
      "name": "Dell XPS 13",
      "description": "Compact ultrabook",
      "price": 1299.99,
      "currency": "USD",
      "image_url": "https://...",
      "category": {
        "id": 5,
        "name": "Laptops"
      },
      "brand": {
        "id": 2,
        "name": "Dell"
      },
      "in_stock": true,
      "discount": null
    }
  ],
  "meta": {
    "current_page": 1,
    "total_pages": 3,
    "total_count": 50,
    "per_page": 20
  }
}
```

#### Get Product Details

```http
GET /api/products/:id
```

**Example Request:**

```bash
curl http://localhost:3000/api/products/1
```

**Response (200 OK):**

```json
{
  "id": 1,
  "name": "Dell XPS 13",
  "description": "Compact ultrabook with premium build quality",
  "price": 1299.99,
  "base_price": 1299.99,
  "discount_price": 1099.99,
  "discount_applied": {
    "id": 5,
    "type": "percentage",
    "value": 15,
    "valid_from": "2026-01-01",
    "valid_to": "2026-02-01"
  },
  "category": {
    "id": 5,
    "name": "Laptops",
    "parent_id": 3
  },
  "brand": {
    "id": 2,
    "name": "Dell"
  },
  "specifications": [
    {
      "attribute": "CPU",
      "value": "Intel Core i7"
    },
    {
      "attribute": "RAM",
      "value": "16GB"
    },
    {
      "attribute": "Storage",
      "value": "512GB SSD"
    }
  ],
  "inventory": {
    "quantity": 15,
    "status": "in_stock"
  },
  "variants": [
    {
      "id": 1,
      "name": "Silver",
      "sku": "XPS13-SLV-001",
      "in_stock": true
    }
  ]
}
```

### Categories

#### List Root Categories

```http
GET /api/categories
```

**Parameters:**

| Parameter | Type | Description |
|-----------|------|-------------|
| `type` | string | Filter by type: `product`, `service`, `both` |

**Example Request:**

```bash
curl http://localhost:3000/api/categories
curl "http://localhost:3000/api/categories?type=product"
```

**Response (200 OK):**

```json
{
  "categories": [
    {
      "id": 1,
      "name": "Electronics",
      "description": "Electronics category",
      "category_type": "product",
      "parent_id": null,
      "children_count": 5
    },
    {
      "id": 2,
      "name": "Clothing",
      "description": "Clothing category",
      "category_type": "product",
      "parent_id": null,
      "children_count": 3
    }
  ]
}
```

#### Get Sub-Categories

```http
GET /api/categories/:id/children
```

**Example Request:**

```bash
curl http://localhost:3000/api/categories/1/children
```

**Response (200 OK):**

```json
[
  {
    "id": 5,
    "name": "Smartphones",
    "parent_id": 1
  },
  {
    "id": 6,
    "name": "Laptops",
    "parent_id": 1
  },
  {
    "id": 7,
    "name": "Tablets",
    "parent_id": 1
  }
]
```

### Shopping Cart

#### View Cart

```http
GET /carts
```

**Example Request:**

```bash
curl http://localhost:3000/carts \
  -H "Cookie: _alshop_session=xyz"
```

**Response (200 OK):**

```json
{
  "id": 10,
  "user_id": 5,
  "items": [
    {
      "id": 45,
      "product_id": 1,
      "product_name": "Dell XPS 13",
      "quantity": 1,
      "unit_price": 1299.99,
      "line_total": 1299.99
    }
  ],
  "subtotal": 1299.99,
  "tax": 129.99,
  "total": 1429.98,
  "item_count": 1,
  "status": "active"
}
```

#### Add to Cart

```http
POST /cart_items
Content-Type: application/json

{
  "sellable_id": 1,
  "quantity": 1,
  "variant_id": (optional)
}
```

**Example Request:**

```bash
curl http://localhost:3000/cart_items \
  -X POST \
  -H "Content-Type: application/json" \
  -H "Cookie: _alshop_session=xyz" \
  -d '{
    "sellable_id": 1,
    "quantity": 2
  }'
```

**Response (201 Created):**

```json
{
  "id": 45,
  "product_id": 1,
  "quantity": 2,
  "unit_price": 1299.99,
  "line_total": 2599.98,
  "message": "Product added to cart"
}
```

#### Update Cart Item

```http
PATCH /cart_items/:id
Content-Type: application/json

{
  "quantity": 3
}
```

**Example Request:**

```bash
curl http://localhost:3000/cart_items/45 \
  -X PATCH \
  -H "Content-Type: application/json" \
  -H "Cookie: _alshop_session=xyz" \
  -d '{
    "quantity": 3
  }'
```

**Response (200 OK):**

```json
{
  "id": 45,
  "quantity": 3,
  "line_total": 3899.97
}
```

#### Remove from Cart

```http
DELETE /cart_items/:id
```

**Example Request:**

```bash
curl http://localhost:3000/cart_items/45 \
  -X DELETE \
  -H "Cookie: _alshop_session=xyz"
```

**Response (204 No Content):**

```
(empty response)
```

### Orders

#### Create Order

```http
POST /orders
Content-Type: application/json

{
  "shipping_address": {
    "first_name": "John",
    "last_name": "Doe",
    "street": "123 Main St",
    "city": "Ulaanbaatar",
    "state": "Tuv",
    "zip": "14200",
    "country": "Mongolia"
  }
}
```

**Authentication:** Required (session or API token)

**Example Request:**

```bash
curl http://localhost:3000/orders \
  -X POST \
  -H "Content-Type: application/json" \
  -H "Cookie: _alshop_session=xyz" \
  -d '{
    "shipping_address": {
      "first_name": "John",
      "last_name": "Doe",
      "street": "123 Main St",
      "city": "Ulaanbaatar",
      "state": "Tuv",
      "zip": "14200",
      "country": "Mongolia"
    }
  }'
```

**Response (201 Created):**

```json
{
  "id": 100,
  "order_number": "ORD-2026-00100",
  "user_id": 5,
  "status": "pending",
  "items": [
    {
      "id": 1,
      "product_id": 1,
      "quantity": 2,
      "unit_price": 1299.99,
      "line_total": 2599.98
    }
  ],
  "subtotal": 2599.98,
  "tax": 259.99,
  "shipping": 50.00,
  "total": 2909.97,
  "shipping_address": {
    "first_name": "John",
    "last_name": "Doe",
    "street": "123 Main St",
    "city": "Ulaanbaatar"
  },
  "created_at": "2026-01-29T10:30:00Z",
  "updated_at": "2026-01-29T10:30:00Z"
}
```

#### Get Order

```http
GET /orders/:id
```

**Authentication:** Required

**Example Request:**

```bash
curl http://localhost:3000/orders/100 \
  -H "Cookie: _alshop_session=xyz"
```

**Response (200 OK):**

```json
{
  "id": 100,
  "order_number": "ORD-2026-00100",
  "status": "paid",
  "items": [
    {
      "product_name": "Dell XPS 13",
      "quantity": 2,
      "unit_price": 1299.99
    }
  ],
  "total": 2909.97,
  "created_at": "2026-01-29T10:30:00Z",
  "payment_status": "completed",
  "fulfillment_status": "pending"
}
```

#### List User Orders

```http
GET /orders
```

**Authentication:** Required

**Parameters:**

| Parameter | Type | Description |
|-----------|------|-------------|
| `status` | string | Filter by status: `pending`, `paid`, `shipped`, `delivered`, `cancelled` |
| `page` | integer | Page number |
| `per_page` | integer | Results per page |

**Example Request:**

```bash
curl "http://localhost:3000/orders?status=paid&page=1" \
  -H "Cookie: _alshop_session=xyz"
```

**Response (200 OK):**

```json
{
  "orders": [
    {
      "id": 100,
      "order_number": "ORD-2026-00100",
      "status": "paid",
      "total": 2909.97,
      "created_at": "2026-01-29T10:30:00Z"
    }
  ],
  "meta": {
    "current_page": 1,
    "total_pages": 2,
    "total_count": 15
  }
}
```

## 🛠️ Service Objects

### PricingCalculator

Calculates final product price including all rules, discounts, and channel pricing.

**Location:** `app/services/pricing_calculator.rb`

**Method:** `.calculate()`

**Parameters:**

| Parameter | Type | Description |
|-----------|------|-------------|
| `sellable` | Sellable | Product or Service object |
| `channel` | String | Sales channel: `web`, `mobile`, `wholesale` |
| `company_id` | Integer | (Optional) Company for B2B pricing |
| `quantity` | Integer | (Optional) Quantity for bulk discounts |

**Example Usage:**

```ruby
# In ProductsController
pricing = PricingCalculator.calculate(
  sellable: product.sellable,
  channel: 'web',
  company_id: nil
)

@product.final_price = pricing[:final_price]
@product.discount = pricing[:discount_applied]
```

**Returns:**

```ruby
{
  base_price: 1299.99,           # Original price
  final_price: 1099.99,          # After discounts
  discount_applied: {            # Discount details
    id: 5,
    type: 'percentage',
    value: 15
  },
  channel_price: 1249.99,        # Channel-specific price
  company_price: nil,            # Company-specific price
  effective_discount: 15.3       # Actual % discount
}
```

### CartToOrderService

Converts a shopping cart into an order.

**Location:** `app/services/cart_to_order_service.rb`

**Method:** `.call()`

**Parameters:**

| Parameter | Type | Description |
|-----------|------|-------------|
| `cart` | Cart | Cart object to convert |
| `user` | User | User placing the order |
| `shipping_address` | Hash | Shipping address |
| `payment_method` | String | (Optional) Payment method |

**Example Usage:**

```ruby
# In OrdersController
result = CartToOrderService.call(
  cart: current_cart,
  user: current_user,
  shipping_address: order_params[:shipping_address],
  payment_method: 'credit_card'
)

if result.success?
  @order = result.order
  redirect_to order_path(@order)
else
  @error = result.error
  render :checkout
end
```

**Returns:**

```ruby
Result object:
{
  success: true,
  order: Order<id: 100, ...>,
  error: nil
}
```

**Error Handling:**

```ruby
# Cart is empty
Result.error('Cart is empty')

# Insufficient inventory
Result.error('Insufficient inventory for item: Dell XPS 13')

# Invalid shipping address
Result.error('Shipping address is incomplete')

# Database transaction failed
Result.error('Order creation failed: ...')
```

## 🔄 Common Workflows

### 1. Browse Products by Category

```
GET /api/categories
  ↓
User selects category
  ↓
GET /api/categories/1/children
  ↓
User selects subcategory
  ↓
GET /api/products?category_id=5
  ↓
Display filtered products
```

### 2. Search and Filter Products

```
User enters search query
  ↓
GET /api/products?q=laptop&min_price=100000&max_price=500000
  ↓
Display results with:
  - Search term highlighted
  - Price range shown
  - Pagination controls
```

### 3. Add Product to Cart

```
User views product
  ↓
GET /api/products/1 (get details)
  ↓
User clicks "Add to Cart"
  ↓
POST /cart_items {sellable_id: 1, quantity: 1}
  ↓
Show success notification
  ↓
Update cart count in header
```

### 4. Complete Purchase

```
User views cart
  ↓
GET /carts (review items)
  ↓
User clicks "Checkout"
  ↓
Enter shipping address
  ↓
POST /orders {shipping_address: {...}}
  ↓
CartToOrderService converts cart to order
  ↓
Show order confirmation
  ↓
Send confirmation email
```

## ⚠️ Error Responses

### 400 Bad Request

```json
{
  "error": "Invalid parameters",
  "details": {
    "min_price": ["must be a number"]
  }
}
```

### 401 Unauthorized

```json
{
  "error": "Authentication required",
  "message": "Please log in to continue"
}
```

### 403 Forbidden

```json
{
  "error": "Not authorized",
  "message": "You don't have permission to access this resource"
}
```

### 404 Not Found

```json
{
  "error": "Resource not found",
  "message": "Product with ID 999 not found"
}
```

### 422 Unprocessable Entity

```json
{
  "error": "Validation failed",
  "errors": [
    "Quantity must be greater than 0"
  ]
}
```

### 500 Internal Server Error

```json
{
  "error": "Server error",
  "message": "An unexpected error occurred. Please try again later."
}
```

## 📝 Request/Response Examples

### Complete Product Browse Workflow

```bash
# 1. Get root categories
curl http://localhost:3000/api/categories

# 2. Get sub-categories
curl http://localhost:3000/api/categories/1/children

# 3. Get products in category
curl "http://localhost:3000/api/products?category_id=5"

# 4. Get product details
curl http://localhost:3000/api/products/1

# 5. Add to cart
curl http://localhost:3000/cart_items \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{"sellable_id": 1, "quantity": 1}'

# 6. View cart
curl http://localhost:3000/carts

# 7. Create order
curl http://localhost:3000/orders \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{
    "shipping_address": {
      "first_name": "John",
      "last_name": "Doe",
      "street": "123 Main St",
      "city": "Ulaanbaatar"
    }
  }'
```

## 🔗 Rate Limiting

Currently no rate limiting. In production, implement:
- 100 requests per minute per IP for public endpoints
- 1000 requests per minute per API token for authenticated endpoints

## 📊 Response Formats

### Success Response (200, 201)

```json
{
  "data": {...},
  "meta": {
    "timestamp": "2026-01-29T10:30:00Z",
    "version": "1.0.0"
  }
}
```

### Paginated Response

```json
{
  "items": [...],
  "meta": {
    "current_page": 1,
    "total_pages": 5,
    "total_count": 100,
    "per_page": 20
  }
}
```

## 🧪 Testing API Endpoints

### Using cURL

```bash
curl http://localhost:3000/api/products
```

### Using HTTPie

```bash
http GET http://localhost:3000/api/products q==laptop
```

### Using Postman

1. Import API endpoints
2. Set environment variables
3. Run requests with pre-configured auth

### Using Ruby

```ruby
require 'httparty'

response = HTTParty.get(
  'http://localhost:3000/api/products',
  query: { q: 'laptop', page: 1 }
)

puts response.parsed_response
```

---

**Last Updated:** January 29, 2026  
**API Version:** 1.0.0  
**Status:** Production Ready
