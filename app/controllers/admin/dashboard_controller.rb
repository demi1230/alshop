module Admin
  class DashboardController < BaseController
    def index
      # Date ranges
      @today = Date.current
      @this_month_start = @today.beginning_of_month
      @last_month_start = @today.last_month.beginning_of_month
      @last_month_end = @today.last_month.end_of_month
      
      # Revenue statistics
      @total_revenue = Order.completed.sum(:total_price)
      @this_month_revenue = Order.completed
        .where(created_at: @this_month_start..@today)
        .sum(:total_price)
      @last_month_revenue = Order.completed
        .where(created_at: @last_month_start..@last_month_end)
        .sum(:total_price)
      @revenue_growth = calculate_growth(@this_month_revenue, @last_month_revenue)
      
      # Order statistics
      @total_orders = Order.count
      @this_month_orders = Order.where(created_at: @this_month_start..@today).count
      @pending_orders = Order.pending.count
      @orders_growth = calculate_growth(
        @this_month_orders,
        Order.where(created_at: @last_month_start..@last_month_end).count
      )
      
      # Product statistics
      @total_products = Product.count
      @active_products = Product.active.count
      @low_stock_products = 0  # TODO: Implement inventory-based stock checking
      @out_of_stock_products = 0  # TODO: Implement inventory-based stock checking
      
      # Customer statistics
      @total_customers = User.where(role: 'customer').count
      @new_customers_this_month = User.where(role: 'customer')
        .where(created_at: @this_month_start..@today)
        .count
      @customers_growth = calculate_growth(
        @new_customers_this_month,
        User.where(role: 'customer')
          .where(created_at: @last_month_start..@last_month_end)
          .count
      )
      
      # Recent orders
      @recent_orders = Order.includes(:user)
        .order(created_at: :desc)
        .limit(10)
      
      # Top selling products
      @top_products = Product
        .joins(sellable: :order_items)
        .select('products.*, sellables.name, SUM(order_items.quantity) as total_sold')
        .group('products.id, sellables.name')
        .order('total_sold DESC')
        .limit(5)
      
      # Low stock alerts - placeholder for now
      @low_stock_items = []
      
      # Recent revenue (for simple display, not charting yet)
      @recent_revenue = Order.completed
        .where(created_at: 30.days.ago..@today)
        .select('DATE(created_at) as date, SUM(total_price) as revenue')
        .group('DATE(created_at)')
        .order('date DESC')
        .limit(30)
    end
    
    private
    
    # Calculate percentage growth
    def calculate_growth(current, previous)
      return 0 if previous.zero?
      ((current - previous).to_f / previous * 100).round(1)
    end
  end
end
