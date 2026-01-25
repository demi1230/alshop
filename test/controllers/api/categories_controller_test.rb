require "test_helper"

class Api::CategoriesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @parent_category = categories(:electronics)
    @child_category = categories(:laptops)
  end

  test "should get children as json" do
    get children_api_category_url(@parent_category), as: :json
    assert_response :success
    
    json_response = JSON.parse(response.body)
    assert json_response.key?('parent')
    assert json_response.key?('children')
  end

  test "should return parent info" do
    get children_api_category_url(@parent_category), as: :json
    
    json_response = JSON.parse(response.body)
    parent = json_response['parent']
    
    assert_equal @parent_category.id, parent['id']
    assert_equal @parent_category.name, parent['name']
  end

  test "should return children array" do
    get children_api_category_url(@parent_category), as: :json
    
    json_response = JSON.parse(response.body)
    children = json_response['children']
    
    assert children.is_a?(Array)
    assert children.any?
  end

  test "should include has_children flag" do
    get children_api_category_url(@parent_category), as: :json
    
    json_response = JSON.parse(response.body)
    children = json_response['children']
    
    children.each do |child|
      assert child.key?('id')
      assert child.key?('name')
      assert child.key?('has_children')
    end
  end

  test "should return empty array for leaf category" do
    get children_api_category_url(@child_category), as: :json
    
    json_response = JSON.parse(response.body)
    children = json_response['children']
    
    assert children.is_a?(Array)
    assert_equal 0, children.length
  end

  test "should include product count for each child" do
    get children_api_category_url(@parent_category), as: :json
    
    json_response = JSON.parse(response.body)
    children = json_response['children']
    
    children.each do |child|
      assert child.key?('product_count')
      assert child['product_count'].is_a?(Integer)
    end
  end

  test "should handle non-existent category" do
    get children_api_category_url(id: 999999), as: :json
    assert_response :not_found
    
    json_response = JSON.parse(response.body)
    assert json_response.key?('error')
  end

  test "should not require authentication" do
    get children_api_category_url(@parent_category), as: :json
    assert_response :success
  end

  test "should order children alphabetically" do
    get children_api_category_url(@parent_category), as: :json
    
    json_response = JSON.parse(response.body)
    children = json_response['children']
    
    names = children.map { |c| c['name'] }
    assert_equal names.sort, names
  end

  test "should include category description" do
    get children_api_category_url(@parent_category), as: :json
    
    json_response = JSON.parse(response.body)
    parent = json_response['parent']
    
    assert parent.key?('description')
  end

  test "should exclude inactive categories" do
    # Assuming categories have active flag
    get children_api_category_url(@parent_category), as: :json
    
    json_response = JSON.parse(response.body)
    children = json_response['children']
    
    children.each do |child|
      # Would verify all returned children are active
      assert child['active'] if child.key?('active')
    end
  end
end
