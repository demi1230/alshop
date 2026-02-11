require 'minitest/autorun'
require_relative '../../models/product'

class ProductTest < Minitest::Test
  def test_product_creation
    product = Product.new(name: "Sample Product", price: 10.0)
    assert_instance_of Product, product
  end

  def test_product_name
    product = Product.new(name: "Sample Product", price: 10.0)
    assert_equal "Sample Product", product.name
  end

  def test_product_price
    product = Product.new(name: "Sample Product", price: 10.0)
    assert_equal 10.0, product.price
  end
end