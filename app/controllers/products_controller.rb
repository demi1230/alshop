# frozen_string_literal: true

# ProductsController - Public product browsing with hierarchical category filtering
# Rails convention: Keep controllers thin, use model scopes for filtering
class ProductsController < ApplicationController
  # No authentication required for browsing products
  before_action :set_categories, only: [:index]

  # GET /products
  # Params:
  #   parent_category_id (optional) - Filter by parent category and all descendants
  #   category_id (optional) - Filter by specific sub-category
  #   q (search query, optional)
  #   page (optional)
  def index
    # Start with base scope using policy (shows active products for non-admins)
    @products = policy_scope(Product)
      .includes(:category, :brand, :sellable) # Eager load to avoid N+1 queries

    # Category filter from dropdown (all/products/services)
    case params[:category]
    when 'services'
      # Redirect to services index if searching in services
      redirect_to services_path(q: params[:q]) and return
    when 'products', 'all', nil
      # Continue with products search
    end

    # Filtering rule: Always use category tree to include all descendants
    if params[:category_id].present?
      @products = @products.in_category_tree(params[:category_id])
      @current_category_id = params[:category_id]
    elsif params[:parent_category_id].present?
      @products = @products.in_category_tree(params[:parent_category_id])
      @current_parent_category_id = params[:parent_category_id]
    end
    
    # Discount filter - check if product has active pricing rules with discounts
    if params[:discount] == "1"
      @products = @products.joins(sellable: :pricing_rules)
        .where(pricing_rules: { discount_type: ['percentage', 'fixed'] })
        .where('pricing_rules.valid_from IS NULL OR pricing_rules.valid_from <= ?', Time.current)
        .where('pricing_rules.valid_to IS NULL OR pricing_rules.valid_to >= ?', Time.current)
        .distinct
    end
    
    # Price range filter
    if params[:min_price].present?
      @products = @products.joins(:sellable).where('sellables.base_price >= ?', params[:min_price])
    end
    if params[:max_price].present?
      @products = @products.joins(:sellable).where('sellables.base_price <= ?', params[:max_price])
    end
    
    # Search
    @products = @products.search(params[:q]) if params[:q].present?
    @current_search_query = params[:q]
    @current_category = params[:category] || 'all'
    
    # Get available brands from current filtered products (BEFORE brand filter is applied)
    # This ensures brand filter always shows all brands available in current category/search
    @available_brands = Brand.joins(:products)
      .merge(@products)
      .distinct
      .order(:name)

    # Apply brand filter AFTER getting available brands
    if params[:brand_id].present?
      @products = @products.where(brand_id: params[:brand_id])
    end
    
    # Sorting
    case params[:sort]
    when 'price_asc'
      @products = @products.joins(:sellable).order('sellables.base_price ASC')
    when 'price_desc'
      @products = @products.joins(:sellable).order('sellables.base_price DESC')
    when 'name_asc'
      @products = @products.joins(:sellable).order('sellables.name ASC')
    when 'name_desc'
      @products = @products.joins(:sellable).order('sellables.name DESC')
    else
      @products = @products.recent
    end
    
    @products = @products.paginate(page: params[:page], per_page: 20)

    if @current_parent_category_id.present? && @current_category_id.blank?
      parent = Category.find_by(id: @current_parent_category_id)
      @sub_categories = parent.children.ordered if parent
    end
  end

  # GET /products/:id
  def show
    @product = Product.includes(:category, :brand, sellable: :sellable_variants).find(params[:id])
    authorize @product

    @variants = @product.available_variants
    @current_price = @product.current_price(user: current_user)
  end

  private

  def set_categories
    # Show hierarchical breadcrumb categories based on current selection
    if params[:category_id].present?
      selected_category = Category.find_by(id: params[:category_id])
      if selected_category
        # Build breadcrumb: grandparent -> parent -> self
        @breadcrumb_categories = []
        
        # Get grandparent if exists
        if selected_category.parent&.parent
          @breadcrumb_categories << selected_category.parent.parent
        end
        
        # Get parent if exists
        if selected_category.parent
          @breadcrumb_categories << selected_category.parent
        end
        
        # Add self
        @breadcrumb_categories << selected_category
        
        @breadcrumb_categories = @breadcrumb_categories.uniq
      end
    elsif params[:parent_category_id].present?
      parent_category = Category.find_by(id: params[:parent_category_id])
      if parent_category
        @breadcrumb_categories = [parent_category]
      end
    end
    
    # Load only product categories for the filter
    @parent_categories = Category.roots.for_products.ordered
  end
end
