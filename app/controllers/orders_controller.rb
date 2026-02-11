class OrdersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_order, only: [:show]

  def index
    @orders = policy_scope(Order).includes(:order_items).paginate(page: params[:page], per_page: 20)
    
    respond_to do |format|
      format.html
      format.json { render json: @orders.as_json(include: :order_items) }
    end
  end

  def show
    authorize @order
    @order_items = @order.order_items.includes(:sellable, :sellable_variant)
    
    respond_to do |format|
      format.html
      format.json { render json: order_json }
    end
  end

  def create
    # Get current cart (works for both logged in users and guests)
    cart = current_cart
    
    # Eager load cart items to avoid N+1 queries
    cart_items = cart&.cart_items&.includes(sellable_variant: :sellable)
    
    if cart.blank? || cart_items.empty?
      redirect_to cart_path, alert: 'Сагс хоосон байна' and return
    end

    # Convert cart to order
    result = CartToOrderService.call(
      cart: cart,
      shipping_address_params: params[:shipping_address] || {}
    )

    if result.success?
      # Clear cart from session (only for guest users)
      session[:cart_id] = nil unless user_signed_in?
      
      respond_to do |format|
        format.html { redirect_to order_path(result.order), notice: 'Захиалга амжилттай үүслээ' }
        format.json { render json: { success: true, order_id: result.order.id }, status: :created }
      end
    else
      respond_to do |format|
        format.html { redirect_to cart_path, alert: result.error }
        format.json { render json: { success: false, error: result.error }, status: :unprocessable_entity }
      end
    end
  end

  private

  def set_order
    @order = Order.find(params[:id])
  end

  def order_params
    params.require(:order).permit(:notes, shipping_address: {}, billing_address: {})
  end

  def order_json
    {
      id: @order.id,
      order_number: @order.order_number,
      status: @order.status,
      total_amount: @order.total_amount,
      shipping_address: @order.shipping_address,
      billing_address: @order.billing_address,
      notes: @order.notes,
      created_at: @order.created_at,
      items: @order.order_items.map do |item|
        {
          id: item.id,
          sellable_name: item.sellable_variant.sellable.name,
          variant_name: item.sellable_variant.variant_name,
          quantity: item.quantity,
          unit_price: item.unit_price,
          subtotal: item.subtotal
        }
      end
    }
  end
end
