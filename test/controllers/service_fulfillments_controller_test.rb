require "test_helper"

class ServiceFulfillmentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @staff = users(:staff)
    @customer = users(:customer)
    @fulfillment = service_fulfillments(:pending_fulfillment)
    sign_in @staff
  end

  test "should get index as staff" do
    get service_fulfillments_url
    assert_response :success
  end

  test "should get index as json" do
    get service_fulfillments_url, as: :json
    assert_response :success
    json_response = JSON.parse(response.body)
    assert json_response.is_a?(Array)
  end

  test "should filter by status" do
    get service_fulfillments_url, params: { status: 'pending' }
    assert_response :success
  end

  test "should show fulfillment" do
    get service_fulfillment_url(@fulfillment)
    assert_response :success
  end

  test "should show fulfillment as json" do
    get service_fulfillment_url(@fulfillment), as: :json
    assert_response :success
    json_response = JSON.parse(response.body)
    assert json_response.key?('id')
    assert json_response.key?('status')
  end

  test "should update fulfillment status" do
    patch service_fulfillment_url(@fulfillment), params: {
      service_fulfillment: { status: 'in_progress' }
    }
    @fulfillment.reload
    assert_equal 'in_progress', @fulfillment.status
    assert_redirected_to service_fulfillment_path(@fulfillment)
  end

  test "should assign staff to fulfillment" do
    patch service_fulfillment_url(@fulfillment), params: {
      service_fulfillment: { assigned_to_id: @staff.id }
    }
    @fulfillment.reload
    assert_equal @staff.id, @fulfillment.assigned_to_id
  end

  test "should complete fulfillment" do
    @fulfillment.update(status: 'in_progress')
    patch service_fulfillment_url(@fulfillment), params: {
      service_fulfillment: { 
        status: 'completed',
        completion_notes: 'Done' 
      }
    }
    @fulfillment.reload
    assert_equal 'completed', @fulfillment.status
    assert_not_nil @fulfillment.completed_at
  end

  test "should update as json" do
    patch service_fulfillment_url(@fulfillment), params: {
      service_fulfillment: { status: 'in_progress' }
    }, as: :json
    assert_response :success
    json_response = JSON.parse(response.body)
    assert json_response['success']
  end

  test "should not allow customer access" do
    sign_in @customer
    get service_fulfillments_url
    assert_response :redirect
    assert_redirected_to root_path
  end

  test "should require authentication" do
    sign_out @staff
    get service_fulfillments_url
    assert_redirected_to new_user_session_path
  end
end
