require "test_helper"

class Admin::ProductsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:admin)
    @product = products(:macbook_pro)
    @category = categories(:laptops)
    @brand = brands(:apple)
    sign_in @admin
  end

  test "should get index" do
    get admin_products_url
    assert_response :success
  end

  test "should get new" do
    get new_admin_product_url
    assert_response :success
  end

  test "should create product" do
    assert_difference ['Sellable.count', 'Product.count'], 1 do
      post admin_products_url, params: {
        product: {
          sellable_attributes: {
            name: 'Тест бүтээгдэхүүн',
            description: 'Тайлбар',
            base_price: 100000,
            company_id: @admin.company_id
          },
          brand_id: @brand.id,
          category_id: @category.id,
          sku: 'TEST-SKU-001',
          warranty_period: 12
        }
      }
    end
    assert_redirected_to admin_products_path
  end

  test "should not create product with non-leaf category" do
    parent_category = categories(:electronics)
    
    assert_no_difference ['Sellable.count', 'Product.count'] do
      post admin_products_url, params: {
        product: {
          sellable_attributes: {
            name: 'Тест',
            base_price: 100000,
            company_id: @admin.company_id
          },
          category_id: parent_category.id
        }
      }
    end
    assert_response :unprocessable_entity
  end

  test "should get edit" do
    get edit_admin_product_url(@product)
    assert_response :success
  end

  test "should update product" do
    patch admin_product_url(@product), params: {
      product: {
        sellable_attributes: {
          id: @product.sellable.id,
          name: 'Шинэчилсэн нэр'
        },
        warranty_period: 24
      }
    }
    @product.reload
    assert_equal 24, @product.warranty_period
    assert_redirected_to admin_products_path
  end

  test "should update product with nested sellable" do
    new_name = 'Өөрчлөгдсөн бүтээгдэхүүн'
    patch admin_product_url(@product), params: {
      product: {
        sellable_attributes: {
          id: @product.sellable.id,
          name: new_name,
          base_price: 200000
        }
      }
    }
    @product.sellable.reload
    assert_equal new_name, @product.sellable.name
    assert_equal 200000, @product.sellable.base_price
  end

  test "should destroy product" do
    assert_difference ['Product.count', 'Sellable.count'], -1 do
      delete admin_product_url(@product)
    end
    assert_redirected_to admin_products_path
  end

  test "should filter by category" do
    get admin_products_url, params: { category_id: @category.id }
    assert_response :success
  end

  test "should filter by brand" do
    get admin_products_url, params: { brand_id: @brand.id }
    assert_response :success
  end

  test "should search by name" do
    get admin_products_url, params: { search: 'MacBook' }
    assert_response :success
  end

  test "should not allow non-admin access" do
    customer = users(:customer)
    sign_in customer
    get admin_products_url
    assert_response :redirect
    assert_redirected_to root_path
  end

  test "should require authentication" do
    sign_out @admin
    get admin_products_url
    assert_redirected_to new_user_session_path
  end
end
