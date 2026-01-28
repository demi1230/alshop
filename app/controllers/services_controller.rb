# frozen_string_literal: true

# ServicesController - Public service browsing with hierarchical category filtering
class ServicesController < ApplicationController
  before_action :set_categories, only: [:index]

  def index
    @services = Service.joins(:sellable)
      .where(sellables: { is_active: true })
      .includes(:category, :sellable)

    # Category filter from dropdown (all/products/services)
    case params[:category]
    when 'products'
      # Redirect to products index if searching in products
      redirect_to products_path(q: params[:q]) and return
    when 'services', 'all', nil
      # Continue with services search
    end

    # Filtering by category - always include descendants
    if params[:category_id].present?
      category = Category.find_by(id: params[:category_id])
      if category
        category_ids = category.descendant_ids
        @services = @services.where(category_id: category_ids)
        @current_category_id = params[:category_id]
      end
    elsif params[:parent_category_id].present?
      parent = Category.find_by(id: params[:parent_category_id])
      if parent
        category_ids = parent.descendant_ids
        @services = @services.where(category_id: category_ids)
        @current_parent_category_id = params[:parent_category_id]
        @sub_categories = parent.children.ordered
      end
    end

    # Search query
    if params[:q].present?
      @services = @services.where('sellables.name LIKE ?', "%#{params[:q]}%")
      @current_search_query = params[:q]
    end
    @current_category = params[:category] || 'all'

    @services = @services.order(created_at: :desc).paginate(page: params[:page], per_page: 20)
  end

  def show
    @service = Service.includes(:sellable, :category, :service_config_specs).find(params[:id])
    @sellable = @service.sellable
    @subscription_plans = @sellable.subscription_plans.includes(:company) if @service.subscription?
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
    
    # Load only service categories for the filter
    @parent_categories = Category.roots.for_services.ordered
  end
end
