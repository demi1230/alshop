class Api::ProductsController < ApplicationController
  skip_before_action :verify_authenticity_token
  
  def index
    @products = Product.includes(:sellable, :category, :brand)
      .paginate(page: params[:page], per_page: params[:per_page] || 20)
    
    # Apply filters
    @products = @products.joins(:sellable).where(sellables: { is_active: true })
    @products = @products.where(category_id: params[:category_id]) if params[:category_id].present?
    @products = @products.where(brand_id: params[:brand_id]) if params[:brand_id].present?
    
    if params[:q].present?
      @products = @products.joins(:sellable).where('sellables.name LIKE ?', "%#{params[:q]}%")
    end
    
    if params[:min_price].present? || params[:max_price].present?
      @products = @products.joins(:sellable)
      @products = @products.where('sellables.base_price >= ?', params[:min_price]) if params[:min_price].present?
      @products = @products.where('sellables.base_price <= ?', params[:max_price]) if params[:max_price].present?
    end

    render json: {
      products: @products.map { |product| product_json(product) },
      meta: {
        current_page: @products.current_page,
        total_pages: @products.total_pages,
        total_count: @products.total_entries,
        per_page: @products.per_page
      }
    }
  end

  def show
    @product = Product.includes(:sellable, :category, :brand).find(params[:id])
    @variants = @product.sellable.sellable_variants.active
    @specifications = @product.sellable.specifications.includes(:category_attribute)
    
    # Calculate pricing using PricingCalculator
    pricing = if defined?(PricingCalculator)
      PricingCalculator.calculate(
        sellable: @product.sellable,
        channel: params[:channel] || 'public_channel',
        company_id: params[:company_id]
      )
    else
      { final_price: @product.sellable.base_price, discount_applied: nil }
    end

    render json: product_json(@product, include_details: true).merge(
      variants: @variants.map { |v| variant_json(v) },
      specifications: @specifications.map { |s| { key: s.category_attribute.name, value: s.value } },
      pricing: pricing
    )
  end

  private

  def product_json(product, include_details: false)
    json = {
      id: product.id,
      name: product.sellable.name,
      base_price: product.sellable.base_price,
      is_active: product.sellable.is_active,
      category: category_json(product.category),
      brand: product.brand ? { id: product.brand.id, name: product.brand.name } : nil
    }
    
    json[:description] = product.sellable.description if include_details
    json
  end

  def category_json(category)
    return nil unless category
    
    {
      id: category.id,
      name: category.name,
      full_path: category.ancestors.pluck(:name).push(category.name).join(' > ')
    }
  end

  def variant_json(variant)
    {
      id: variant.id,
      variant_name: variant.variant_name,
      sku: variant.sku,
      price_override: variant.price_override,
      attributes: variant.attributes_data,
      is_active: variant.is_active,
      inventory: variant.inventory&.quantity || 0
    }
  end
end
