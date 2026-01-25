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
    @order_items = @order.order_items.includes(sellable_variant: { sellable: [:brand, product: :category] })
    
    respond_to do |format|
      format.html
      format.json { render json: order_json }
    end
  end

  def create
    cart = current_user.cart
    
    if cart.cart_items.empty?
      redirect_to cart_path, alert: 'Сагс хоосон байна' and return
    end

    result = CartToOrderService.call(
      cart: cart,
      shipping_address_params: order_params[:shipping_address],
      billing_address_params: order_params[:billing_address],
      notes: order_params[:notes]
    )

    if result.success?
      @order = result.order
      respond_to do |format|
        format.html { redirect_to order_path(@order), notice: 'Захиалга амжилттай үүслээ' }
        format.json { render json: { success: true, order: order_json }, status: :created }
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
