require "test_helper"

class Admin::OrdersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:admin)
    @order = orders(:customer_order)
    sign_in @admin
  end

  test "should get index" do
    get admin_orders_url
    assert_response :success
  end

  test "should filter by status" do
    get admin_orders_url, params: { status: 'pending' }
    assert_response :success
  end

  test "should filter by date range" do
    get admin_orders_url, params: { 
      start_date: 1.week.ago.to_date,
      end_date: Date.today
    }
    assert_response :success
  end

  test "should search by order number" do
    get admin_orders_url, params: { search: @order.order_number }
    assert_response :success
  end

  test "should show order" do
    get admin_order_url(@order)
    assert_response :success
  end

  test "should mark order as paid" do
    @order.update(payment_status: 'pending')
    
    patch mark_paid_admin_order_url(@order)
    @order.reload
    
    assert_equal 'paid', @order.payment_status
    assert_not_nil @order.paid_at
    assert_redirected_to admin_order_path(@order)
  end

  test "should mark order as shipped" do
    @order.update(status: 'processing', payment_status: 'paid')
    
    patch mark_shipped_admin_order_url(@order), params: {
      tracking_number: 'TRACK123'
    }
    @order.reload
    
    assert_equal 'shipped', @order.status
    assert_equal 'TRACK123', @order.tracking_number
    assert_not_nil @order.shipped_at
    assert_redirected_to admin_order_path(@order)
  end

  test "should not ship unpaid order" do
    @order.update(payment_status: 'pending')
    
    patch mark_shipped_admin_order_url(@order)
    @order.reload
    
    assert_not_equal 'shipped', @order.status
    assert_response :unprocessable_entity
  end

  test "should cancel order" do
    @order.update(status: 'pending')
    
    patch cancel_admin_order_url(@order), params: {
      cancellation_reason: 'Хэрэглэгч хүсэлт'
    }
    @order.reload
    
    assert_equal 'cancelled', @order.status
    assert_equal 'Хэрэглэгч хүсэлт', @order.cancellation_reason
    assert_not_nil @order.cancelled_at
    assert_redirected_to admin_order_path(@order)
  end

  test "should not cancel completed order" do
    @order.update(status: 'completed')
    
    patch cancel_admin_order_url(@order)
    @order.reload
    
    assert_equal 'completed', @order.status
    assert_response :unprocessable_entity
  end

  test "should show order statistics" do
    get admin_orders_url
    assert_response :success
    # Would check for statistics in view
  end

  test "should export orders" do
    get admin_orders_url, params: { format: :csv }
    assert_response :success
    assert_equal 'text/csv', response.content_type
  end

  test "should update order notes" do
    patch admin_order_url(@order), params: {
      order: {
        admin_notes: 'Шинэ тэмдэглэл'
      }
    }
    @order.reload
    assert_equal 'Шинэ тэмдэглэл', @order.admin_notes
  end

  test "should not allow non-admin access" do
    customer = users(:customer)
    sign_in customer
    get admin_orders_url
    assert_response :redirect
    assert_redirected_to root_path
  end

  test "should require authentication" do
    sign_out @admin
    get admin_orders_url
    assert_redirected_to new_user_session_path
  end
end
