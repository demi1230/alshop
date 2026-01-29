# AlShop - Modern E-Commerce Platform for Mongolia

A modern, production-ready Rails e-commerce application built with clean architecture principles, featuring hierarchical product categories, dynamic filtering, and responsive UI.

## 🎯 Features

### Product Catalog
- **Hierarchical Categories** - Parent/child category structure for flexible product organization
- **Advanced Filtering** - Filter by category, brand, price range, and discounts
- **Full-Text Search** - Instant search with debounced input across product names
- **Responsive Grid Layout** - Mobile-first Tailwind CSS design (1/2/3/4 columns)
- **Pagination** - will_paginate gem for smooth pagination

### Shopping Experience
- **Dynamic Category Dropdown** - Automatic sub-category loading via Stimulus Fetch API
- **Price Filtering** - Min/max price range filters
- **Brand Selection** - Filter by available brands in current category
- **Sorting Options** - Sort by price (asc/desc) and name (A-Z/Z-A)
- **Shopping Cart** - Session-based cart with quantity management

### Admin Panel
- **Product Management** - Create, edit, delete products with bulk operations
- **Category Management** - Create hierarchical categories
- **Pricing Rules** - Manage discounts and pricing rules
- **Service Management** - Manage services with fulfillment tracking
- **Order Management** - View and manage customer orders

## 🛠️ Technology Stack

### Backend
- **Rails 8.1.2** - Latest Rails with Hotwire
- **Ruby 3.4.8** - Modern Ruby with pattern matching
- **SQLite 3** - Development/production database
- **Devise** - User authentication
- **Pundit** - Authorization/authorization

### Frontend
- **Tailwind CSS 4.4** - Utility-first styling
- **Hotwire Turbo** - Fast page navigation without full reloads
- **Stimulus JS** - Lightweight framework for interactivity
- **will_paginate** - Pagination gem

### Infrastructure
- **Docker** - Containerization for deployment
- **Kamal** - Docker deployment tool
- **Puma** - Production web server
- **Thruster** - HTTP caching and compression

## 📋 Requirements

- Ruby 3.4.8 or higher
- SQLite 3
- Node.js 18+ (for JavaScript compilation)
- Docker (for containerized deployment)

## 🚀 Quick Start

### Local Development Setup

#### 1. Clone the Repository
```bash
git clone https://github.com/demi1230/alshop.git
cd alshop
```

#### 2. Install Dependencies
```bash
bundle install
npm install
```

#### 3. Setup Database
```bash
rails db:create
rails db:migrate
rails db:seed
```

The seed file creates:
- 10 sample users (various roles)
- 20 products across 5 categories
- 10 services
- Pricing rules and discounts
- 20 sample orders

#### 4. Start Development Server
```bash
./bin/dev
```

This runs:
- Rails server on `http://localhost:3000`
- Tailwind CSS watcher
- Stimulus hot reloading

Open `http://localhost:3000` in your browser.

#### 5. Admin Access
```
Email: admin@example.com
Password: password123
```

Admin panel available at `/admin/dashboard`

### Environment Variables

Create a `.env` file (or `.env.local` for local overrides):

```bash
# Rails Configuration
RAILS_ENV=development
RAILS_LOG_TO_STDOUT=true

# Database (SQLite default, no configuration needed)
# Use DATABASE_URL for Postgres in production

# Session Secret
SECRET_KEY_BASE=<generated during setup>

# Email (optional, uses letter_opener in dev)
MAIL_HOST=localhost
MAIL_PORT=3000
```

## 📚 Documentation

- **[ARCHITECTURE.md](docs/ARCHITECTURE.md)** - System design, patterns, and philosophy
- **[API_GUIDE.md](docs/API_GUIDE.md)** - Complete API reference and endpoint documentation
- **[DEPLOYMENT.md](docs/DEPLOYMENT.md)** - Railway deployment and production setup
- **[PROJECT_STATUS.md](docs/PROJECT_STATUS.md)** - Current development status and roadmap

## 📦 Project Structure

```
app/
├── controllers/
│   ├── products_controller.rb      # Public product browsing
│   ├── services_controller.rb      # Public service browsing
│   ├── cart_items_controller.rb    # Shopping cart
│   ├── orders_controller.rb        # Order management
│   ├── api/
│   │   ├── products_controller.rb  # JSON API
│   │   └── categories_controller.rb
│   └── admin/                      # Admin panel
│
├── models/
│   ├── product.rb                  # Product model
│   ├── category.rb                 # Hierarchical categories
│   ├── brand.rb                    # Brand model
│   ├── order.rb                    # Order management
│   ├── cart.rb                     # Shopping cart
│   └── user.rb                     # User/authentication
│
├── services/
│   ├── pricing_calculator.rb       # Dynamic pricing
│   └── cart_to_order_service.rb    # Cart → Order conversion
│
├── javascript/
│   └── controllers/
│       ├── product_filter_controller.js    # Search & sorting
│       └── category_filter_controller.js   # Category dropdown
│
└── views/
    ├── products/
    │   ├── index.html.erb          # Product listing (main page)
    │   ├── show.html.erb           # Product detail
    │   └── _card.html.erb          # Product card component
    ├── services/                   # Service pages
    ├── carts/                      # Shopping cart
    └── layouts/                    # App layouts

config/
├── routes.rb                       # URL routing
├── database.yml                    # Database configuration
└── environments/                   # Environment configs

db/
├── schema.rb                       # Database schema
├── seeds.rb                        # Production seed data
├── migrate/                        # Database migrations
└── seeds_mongolian_example.rb      # Example seed data

spec/ or test/                      # Test suite
```

## 🎨 Features in Detail

### Hierarchical Categories

Categories support parent-child relationships for flexible organization:

```
Electronics
├── Smartphones
│   ├── iPhones
│   └── Samsung Phones
└── Laptops
    ├── Gaming Laptops
    └── Ultrabooks
```

**Managing Categories:**
```ruby
# Create parent category
cat = Category.create!(name: "Electronics", category_type: "product")

# Create child category
subcategory = Category.create!(
  name: "Smartphones",
  category_type: "product",
  parent: cat
)

# Get all descendants
all_products = Product.in_category_tree(cat.id)
```

### Product Filtering & Search

The product listing page supports:

1. **Category Filter** - Shows hierarchical breadcrumb with parent/child selection
2. **Brand Filter** - Radio buttons showing brands in current category
3. **Price Range** - Min/max filter with numeric inputs
4. **Discount Filter** - Show only discounted items
5. **Search** - Debounced text search across product names

**API Usage:**
```bash
# Filter by category
GET /api/products?category_id=5

# Search and filter
GET /api/products?q=laptop&min_price=500000&max_price=2000000

# Sort by price
GET /api/products?sort=price_asc

# Pagination
GET /api/products?page=2&per_page=20
```

### Stimulus Controllers

Two lightweight Stimulus controllers handle frontend interactivity:

#### ProductFilterController
- Auto-submits form on category change
- Debounces search input (500ms default)
- Maintains form state across filters

#### CategoryFilterController
- Loads sub-categories via Fetch API
- Dynamically populates dropdown
- Disables sub-category when parent not selected

## 🧪 Testing

Run tests with:

```bash
# Run all tests
rails test

# Run specific test file
rails test test/models/product_test.rb

# Run tests with coverage
rails test --coverage
```

Current test coverage:
- ✅ 239 tests across models, controllers, and services
- ✅ 532 assertions
- ✅ All integration tests passing

## 🔐 Security

- **User Authentication** - Devise gem with secure passwords
- **Authorization** - Pundit gem for role-based access control
- **CSRF Protection** - Rails built-in token validation
- **SQL Injection Prevention** - Parameterized queries throughout
- **XSS Protection** - HTML escaping in ERB templates

**Admin Access Control:**
- Only users with `admin` role can access `/admin` panel
- Order management restricted to authenticated users
- Public product browsing available to all

## 📱 Mobile Responsiveness

Built with mobile-first approach using Tailwind CSS:

- **Mobile** - 1 column grid
- **Tablet** - 2-3 columns
- **Desktop** - 3-4 columns
- **Wide** - 4 columns

All filters, search, and navigation optimized for touch.

## 🚀 Deployment

### Railway Deployment

See [DEPLOYMENT.md](docs/DEPLOYMENT.md) for complete setup instructions.

Quick start:

```bash
# Install Railway CLI
npm i -g @railway/cli

# Login and setup project
railway login
railway init

# Deploy
railway up
```

### Docker Deployment

```bash
# Build image
docker build -t alshop .

# Run container
docker run -p 3000:3000 \
  -e RAILS_MASTER_KEY=your-key \
  alshop
```

## 🤝 Contributing

1. Create a feature branch (`git checkout -b feature/amazing-feature`)
2. Commit changes (`git commit -m 'Add amazing feature'`)
3. Push to branch (`git push origin feature/amazing-feature`)
4. Open Pull Request

## 📝 License

This project is licensed under the MIT License - see LICENSE file for details.

## 📞 Support

For issues, questions, or suggestions:
- Create a GitHub issue
- Check existing documentation in `/docs`
- Review code comments for implementation details

## 🗂️ File Manifest

| File | Purpose |
|------|---------|
| `app/` | Application code (models, controllers, views) |
| `config/` | Rails configuration |
| `db/` | Database migrations and seeds |
| `public/` | Static files |
| `test/` | Test suite |
| `Dockerfile` | Docker container definition |
| `Gemfile` | Ruby dependencies |
| `Procfile.dev` | Development process management |

## 🎓 Learning Resources

- [Rails Guides](https://guides.rubyonrails.org)
- [Tailwind CSS Docs](https://tailwindcss.com/docs)
- [Hotwire Handbook](https://hotwired.dev)
- [Stimulus Handbook](https://stimulus.hotwired.dev)

---

**Current Version:** 1.0.0  
**Last Updated:** January 29, 2026  
**Status:** Production Ready
