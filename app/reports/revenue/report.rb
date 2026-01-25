# frozen_string_literal: true

module Revenue
  # Business metrics and calculations for revenue analysis
  # Uses Revenue::Query for data retrieval, then computes metrics
  class Report
    def self.call(**options)
      new(**options).call
    end

    def initialize(status: nil, user_id: nil, company_id: nil, from_date: nil, to_date: nil, group_by: nil)
      @status = status
      @user_id = user_id
      @company_id = company_id
      @from_date = from_date
      @to_date = to_date
      @group_by = group_by
    end

    def call
      query_result = Revenue::Query.call(
        status: @status,
        user_id: @user_id,
        company_id: @company_id,
        from_date: @from_date,
        to_date: @to_date
      )

      orders = query_result.orders

      if @group_by.present?
        Result.new(orders: orders, group_by: @group_by)
      else
        Result.new(orders: orders)
      end
    end

    class Result
      def initialize(orders:, group_by: nil)
        @orders = orders
        @group_by = group_by
        @metrics_cache = {}
      end

      # === Aggregate Metrics ===

      def total_revenue
        @metrics_cache[:total_revenue] ||= @orders.sum(:total_price)
      end

      def total_refunded
        @metrics_cache[:total_refunded] ||= calculate_total_refunded
      end

      def net_revenue
        total_revenue - total_refunded
      end

      def order_count
        @metrics_cache[:order_count] ||= @orders.count
      end

      def average_order_value
        return 0 if order_count.zero?
        total_revenue / order_count
      end

      def refund_rate
        return 0 if total_revenue.zero?
        (total_refunded / total_revenue * 100).round(2)
      end

      # === Time-based Grouping ===

      def by_date
        return nil unless @group_by.present?
        @metrics_cache[:by_date] ||= calculate_by_date
      end

      private

      def calculate_total_refunded
        total = 0
        @orders.find_each do |order|
          next unless order.metadata.is_a?(Hash)
          
          refunds = order.metadata['refunds'] || order.metadata[:refunds] || []
          refunds.each do |r|
            total += (r['amount'] || r[:amount] || 0).to_f
          end
        end
        total
      end

      def calculate_by_date
        grouped = {}

        @orders.find_each do |order|
          date_key = group_date(order.created_at)
          grouped[date_key] ||= []
          grouped[date_key] << order
        end

        # Calculate metrics for each group
        grouped.transform_values do |orders_in_period|
          calculate_period_metrics(orders_in_period)
        end
      end

      def group_date(timestamp)
        case @group_by
        when 'day'
          timestamp.to_date
        when 'week'
          timestamp.to_date.beginning_of_week
        when 'month'
          Date.new(timestamp.year, timestamp.month, 1)
        when 'year'
          Date.new(timestamp.year, 1, 1)
        else
          timestamp.to_date
        end
      end

      def calculate_period_metrics(orders)
        total_rev = orders.sum(&:total_price)
        total_ref = calculate_refunded_for_orders(orders)

        {
          total_revenue: total_rev,
          total_refunded: total_ref,
          net_revenue: total_rev - total_ref,
          order_count: orders.count,
          average_order_value: orders.empty? ? 0 : total_rev / orders.count
        }
      end

      def calculate_refunded_for_orders(orders)
        total = 0
        orders.each do |order|
          next unless order.metadata.is_a?(Hash)
          
          refunds = order.metadata['refunds'] || order.metadata[:refunds] || []
          refunds.each do |r|
            total += (r['amount'] || r[:amount] || 0).to_f
          end
        end
        total
      end
    end
  end
end
