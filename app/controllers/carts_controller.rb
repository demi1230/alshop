class CartsController < ApplicationController
  before_action :set_cart

  def show
    @cart_items = @cart.cart_items.includes(sellable_variant: { sellable: [:brand, product: :category] })
    
    respond_to do |format|
      format.html
      format.json { render json: cart_json }
    end
  end

  def clear
    @cart.cart_items.destroy_all
    
    respond_to do |format|
      format.html { redirect_to cart_path, notice: 'Сагс хоослогдлоо' }
      format.json { render json: { success: true, message: 'Cart cleared' } }
    end
  end

  private

  def set_cart
    @cart = current_cart
  end

  def cart_json
    {
      id: @cart.id,
      items: @cart.cart_items.map do |item|
        {
          id: item.id,
          sellable: item.sellable.as_json(only: [:id, :name, :base_price]),
          variant: item.sellable_variant&.as_json(only: [:id, :variant_name, :sku, :price_override]),
          quantity: item.quantity,
          configuration: item.configuration,
          line_price: item.line_price_estimate || 0
        }
      end,
      total: @cart.cart_items.sum(:line_price_estimate) || 0
    }
  end
end
