require "test_helper"

class Admin::CategoriesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:admin)
    @category = categories(:laptops)
    @parent_category = categories(:electronics)
    sign_in @admin
  end

  test "should get index" do
    get admin_categories_url
    assert_response :success
  end

  test "should get new" do
    get new_admin_category_url
    assert_response :success
  end

  test "should create category" do
    assert_difference 'Category.count', 1 do
      post admin_categories_url, params: {
        category: {
          name: 'Шинэ ангилал',
          description: 'Тайлбар',
          parent_id: @parent_category.id
        }
      }
    end
    assert_redirected_to admin_categories_path
  end

  test "should create root category" do
    assert_difference 'Category.count', 1 do
      post admin_categories_url, params: {
        category: {
          name: 'Үндсэн ангилал',
          description: 'Тайлбар'
        }
      }
    end
    new_category = Category.last
    assert_nil new_category.parent_id
  end

  test "should get edit" do
    get edit_admin_category_url(@category)
    assert_response :success
  end

  test "should update category" do
    patch admin_category_url(@category), params: {
      category: {
        name: 'Шинэчилсэн ангилал',
        description: 'Шинэ тайлбар'
      }
    }
    @category.reload
    assert_equal 'Шинэчилсэн ангилал', @category.name
    assert_redirected_to admin_categories_path
  end

  test "should update category parent" do
    new_parent = categories(:fashion)
    patch admin_category_url(@category), params: {
      category: {
        parent_id: new_parent.id
      }
    }
    @category.reload
    assert_equal new_parent.id, @category.parent_id
  end

  test "should not allow circular parent relationship" do
    child = categories(:gaming_laptops)
    patch admin_category_url(@category), params: {
      category: {
        parent_id: child.id
      }
    }
    assert_response :unprocessable_entity
  end

  test "should destroy category without children" do
    leaf_category = categories(:gaming_laptops)
    # Remove associated products first
    leaf_category.products.destroy_all
    
    assert_difference 'Category.count', -1 do
      delete admin_category_url(leaf_category)
    end
    assert_redirected_to admin_categories_path
  end

  test "should not destroy category with children" do
    assert_no_difference 'Category.count' do
      delete admin_category_url(@parent_category)
    end
    assert_redirected_to admin_categories_path
    assert_match /children/, flash[:alert]
  end

  test "should not destroy category with products" do
    assert_no_difference 'Category.count' do
      delete admin_category_url(@category)
    end
    assert_redirected_to admin_categories_path
    assert_match /products/, flash[:alert]
  end

  test "should show category hierarchy" do
    get admin_categories_url
    assert_response :success
    # Test would check for proper hierarchy display in view
  end

  test "should not allow non-admin access" do
    customer = users(:customer)
    sign_in customer
    get admin_categories_url
    assert_response :redirect
    assert_redirected_to root_path
  end

  test "should require authentication" do
    sign_out @admin
    get admin_categories_url
    assert_redirected_to new_user_session_path
  end
end
