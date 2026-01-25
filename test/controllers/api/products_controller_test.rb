require "test_helper"

class Api::ProductsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @product = products(:macbook_pro)
    @category = categories(:laptops)
    @brand = brands(:apple)
  end

  test "should get index as json" do
    get api_products_url, as: :json
    assert_response :success
    
    json_response = JSON.parse(response.body)
    assert json_response.key?('data')
    assert json_response.key?('meta')
    assert json_response['data'].is_a?(Array)
  end

  test "should include pagination meta" do
    get api_products_url, as: :json
    
    json_response = JSON.parse(response.body)
    meta = json_response['meta']
    
    assert meta.key?('current_page')
    assert meta.key?('total_pages')
    assert meta.key?('total_count')
    assert meta.key?('per_page')
  end

  test "should filter by category" do
    get api_products_url, params: { category_id: @category.id }, as: :json
    assert_response :success
    
    json_response = JSON.parse(response.body)
    json_response['data'].each do |product|
      assert_equal @category.id, product['category_id']
    end
  end

  test "should filter by brand" do
    get api_products_url, params: { brand_id: @brand.id }, as: :json
    assert_response :success
    
    json_response = JSON.parse(response.body)
    json_response['data'].each do |product|
      assert_equal @brand.id, product['brand_id']
    end
  end

  test "should filter by price range" do
    get api_products_url, params: { 
      min_price: 500000, 
      max_price: 2000000 
    }, as: :json
    assert_response :success
    
    json_response = JSON.parse(response.body)
    json_response['data'].each do |product|
      assert product['price'] >= 500000
      assert product['price'] <= 2000000
    end
  end

  test "should search by query" do
    get api_products_url, params: { q: 'MacBook' }, as: :json
    assert_response :success
    
    json_response = JSON.parse(response.body)
    assert json_response['data'].any?
  end

  test "should sort products" do
    get api_products_url, params: { 
      sort_by: 'price', 
      direction: 'asc' 
    }, as: :json
    assert_response :success
    
    json_response = JSON.parse(response.body)
    prices = json_response['data'].map { |p| p['price'] }
    assert_equal prices.sort, prices
  end

  test "should paginate results" do
    get api_products_url, params: { page: 1, per_page: 10 }, as: :json
    assert_response :success
    
    json_response = JSON.parse(response.body)
    assert json_response['data'].length <= 10
    assert_equal 1, json_response['meta']['current_page']
  end

  test "should show product with pricing" do
    get api_product_url(@product), as: :json
    assert_response :success
    
    json_response = JSON.parse(response.body)
    assert json_response.key?('id')
    assert json_response.key?('name')
    assert json_response.key?('price')
    assert json_response.key?('discounted_price')
    assert json_response.key?('variants')
  end

  test "should include variants in product show" do
    get api_product_url(@product), as: :json
    
    json_response = JSON.parse(response.body)
    assert json_response.key?('variants')
    assert json_response['variants'].is_a?(Array)
  end

  test "should calculate pricing with context" do
    get api_product_url(@product), params: { 
      channel: 'online',
      quantity: 10
    }, as: :json
    
    json_response = JSON.parse(response.body)
    assert json_response.key?('price')
    # Would verify PricingCalculator was called with correct params
  end

  test "should include category and brand info" do
    get api_product_url(@product), as: :json
    
    json_response = JSON.parse(response.body)
    assert json_response.key?('category')
    assert json_response.key?('brand')
    assert json_response['category'].key?('name')
    assert json_response['brand'].key?('name')
  end

  test "should handle non-existent product" do
    get api_product_url(id: 999999), as: :json
    assert_response :not_found
    
    json_response = JSON.parse(response.body)
    assert json_response.key?('error')
  end

  test "should filter by in_stock" do
    get api_products_url, params: { in_stock: true }, as: :json
    assert_response :success
    
    json_response = JSON.parse(response.body)
    json_response['data'].each do |product|
      assert product['in_stock']
    end
  end

  test "should not require authentication" do
    get api_products_url, as: :json
    assert_response :success
  end
end
