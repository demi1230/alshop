class CartItemsController < ApplicationController
  before_action :set_cart
  before_action :set_cart_item, only: [:update, :destroy]

  def create
    variant_id = cart_item_params[:sellable_variant_id]
    
    # If no variant specified, find or create default variant for sellable
    if variant_id.blank?
      sellable_id = params[:cart_item][:sellable_id] || params[:sellable_id]
      
      if sellable_id.blank?
        return respond_to do |format|
          format.html { redirect_back fallback_location: root_path, alert: 'Бараа сонгоно уу' }
          format.json { render json: { success: false, error: 'No sellable specified' }, status: :unprocessable_entity }
        end
      end
      
      sellable = Sellable.find(sellable_id)
      variant = sellable.sellable_variants.first
      
      unless variant
        return respond_to do |format|
          format.html { redirect_back fallback_location: root_path, alert: 'Энэ бараа дууссан байна' }
          format.json { render json: { success: false, error: 'No variants available' }, status: :unprocessable_entity }
        end
      end
    else
      variant = SellableVariant.find(variant_id)
    end
    
    @cart_item = @cart.cart_items.find_or_initialize_by(
      sellable_variant_id: variant.id,
      sellable_id: variant.sellable_id
    )
    
    if @cart_item.new_record?
      @cart_item.quantity = cart_item_params[:quantity] || 1
      @cart_item.configuration = cart_item_params[:configuration]
    else
      @cart_item.quantity += (cart_item_params[:quantity] || 1).to_i
    end

    if @cart_item.save
      respond_to do |format|
        format.html { redirect_to cart_path, notice: 'Бараа нэмэгдлээ' }
        format.json { render json: { success: true, cart_item: cart_item_json(@cart_item), cart_count: @cart.cart_items.sum(:quantity) }, status: :created }
      end
    else
      respond_to do |format|
        format.html { redirect_to :back, alert: @cart_item.errors.full_messages.join(', ') }
        format.json { render json: { success: false, errors: @cart_item.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def update
    quantity = params[:cart_item]&.dig(:quantity) || params.dig(:cart_item, :quantity) || params[:quantity]
    configuration = params[:cart_item]&.dig(:configuration) || params.dig(:cart_item, :configuration)
    
    if @cart_item.update(quantity: quantity, configuration: configuration)
      respond_to do |format|
        format.html { redirect_to cart_path, notice: 'Шинэчлэгдлээ' }
        format.json { render json: { success: true, cart_item: cart_item_json(@cart_item) } }
      end
    else
      respond_to do |format|
        format.html { redirect_to cart_path, alert: @cart_item.errors.full_messages.join(', ') }
        format.json { render json: { success: false, errors: @cart_item.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @cart_item.destroy
    
    respond_to do |format|
      format.html { redirect_to cart_path, notice: 'Бараа хасагдлаа' }
      format.json { render json: { success: true, cart_count: @cart.cart_items.sum(:quantity) } }
    end
  end

  private

  def set_cart
    @cart = current_cart
  end

  def set_cart_item
    @cart_item = @cart.cart_items.find(params[:id])
  end

  def cart_item_params
    params.require(:cart_item).permit(:sellable_variant_id, :quantity, configuration: {})
  end

  def cart_item_json(item)
    {
      id: item.id,
      quantity: item.quantity,
      configuration: item.configuration,
      line_price: item.line_price_estimate || 0
    }
  end
end
