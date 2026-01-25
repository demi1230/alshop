require "test_helper"

class Admin::BrandsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:admin)
    @brand = brands(:apple)
    sign_in @admin
  end

  test "should get index" do
    get admin_brands_url
    assert_response :success
  end

  test "should get new" do
    get new_admin_brand_url
    assert_response :success
  end

  test "should create brand" do
    assert_difference 'Brand.count', 1 do
      post admin_brands_url, params: {
        brand: {
          name: 'Шинэ брэнд',
          website_url: 'https://example.com'
        }
      }
    end
    assert_redirected_to admin_brands_path
  end

  test "should not create brand with duplicate name" do
    assert_no_difference 'Brand.count' do
      post admin_brands_url, params: {
        brand: {
          name: @brand.name
        }
      }
    end
    assert_response :unprocessable_entity
  end

  test "should show brand" do
    get admin_brand_url(@brand)
    assert_response :success
  end

  test "should get edit" do
    get edit_admin_brand_url(@brand)
    assert_response :success
  end

  test "should update brand" do
    patch admin_brand_url(@brand), params: {
      brand: {
        name: 'Шинэчилсэн брэнд',
        description: 'Шинэ тайлбар'
      }
    }
    @brand.reload
    assert_equal 'Шинэчилсэн брэнд', @brand.name
    assert_redirected_to admin_brand_path(@brand)
  end

  test "should update brand website" do
    new_website = 'https://newsite.com'
    patch admin_brand_url(@brand), params: {
      brand: {
        website_url: new_website
      }
    }
    @brand.reload
    assert_equal new_website, @brand.website_url
  end

  test "should destroy brand without products" do
    brand_without_products = brands(:unused_brand)
    
    assert_difference 'Brand.count', -1 do
      delete admin_brand_url(brand_without_products)
    end
    assert_redirected_to admin_brands_path
  end

  test "should not destroy brand with products" do
    assert_no_difference 'Brand.count' do
      delete admin_brand_url(@brand)
    end
    assert_redirected_to admin_brands_path
    assert_match /products/, flash[:alert]
  end

  test "should search brands" do
    get admin_brands_url, params: { search: 'Apple' }
    assert_response :success
  end

  test "should paginate brands" do
    get admin_brands_url, params: { page: 1 }
    assert_response :success
  end

  test "should not allow non-admin access" do
    customer = users(:customer)
    sign_in customer
    get admin_brands_url
    assert_response :redirect
    assert_redirected_to root_path
  end

  test "should require authentication" do
    sign_out @admin
    get admin_brands_url
    assert_redirected_to new_user_session_path
  end
end
