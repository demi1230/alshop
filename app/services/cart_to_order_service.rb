# frozen_string_literal: true

require 'ostruct'

# CartToOrderService - Converts a cart into an immutable order
# with snapshotted prices and configuration.
#
# Simplified for internship project - focuses on core order creation logic.
#
# Usage:
#   result = CartToOrderService.call(
#     cart: active_cart,
#     shipping_address_params: { city: "NYC", phone_number: "555-1234" }
#   )
#
#   if result.success?
#     redirect_to result.order
#   else
#     flash[:error] = result.error
#   end
#
class CartToOrderService
  def self.call(cart:, shipping_address_params: {})
    new(cart: cart, shipping_address_params: shipping_address_params).call
  end

  def initialize(cart:, shipping_address_params: {})
    @cart = cart
    @user = cart.user
    @shipping_address_params = shipping_address_params
  end

  def call
    validate!

    order = nil
    ActiveRecord::Base.transaction do
      order = create_order
      create_order_items(order)
      create_shipping_address(order) if shipping_address_params.present?
      cart.convert_to_order!
    end

    success(order)
  rescue ValidationError => e
    failure(e.message)
  rescue ActiveRecord::RecordInvalid => e
    failure(e.message)
  end

  private

  attr_reader :cart, :user, :shipping_address_params

  def validate!
    raise ValidationError, "Cart cannot be nil" if cart.nil?
    raise ValidationError, "Cart is empty" if cart.empty?
    raise ValidationError, "Cart is not active" unless cart.active?

    cart.cart_items.each do |item|
      raise ValidationError, "#{item.sellable.name} is no longer available" unless item.sellable.is_active
    end
  end

  def create_order
    Order.create!(
      user: user,
      status: :pending,
      total_price: calculate_total_price,
      metadata: {
        cart_id: cart.id,
        created_via: 'cart_checkout'
      }
    )
  end

  def create_order_items(order)
    cart.cart_items.each do |cart_item|
      price = calculate_price_for_item(cart_item)

      # Deduct inventory for products (not services)
      if cart_item.sellable.sellable_type == 'Product'
        inventory = cart_item.sellable_variant&.inventory
        
        unless inventory
          raise ValidationError, "#{cart_item.sellable.name} барааны үлдэгдлийн мэдээлэл олдсонгүй"
        end
        
        if inventory.quantity < cart_item.quantity
          raise ValidationError, "#{cart_item.sellable.name} барааны үлдэгдэл хүрэлцэхгүй байна (Хүссэн: #{cart_item.quantity}, Үлдсэн: #{inventory.quantity})"
        end
        
        inventory.update!(quantity: inventory.quantity - cart_item.quantity)
      end

      OrderItem.create!(
        order: order,
        sellable: cart_item.sellable,
        sellable_variant: cart_item.sellable_variant,
        quantity: cart_item.quantity,
        price_at_purchase: price,
        line_total: (price * cart_item.quantity).round(2),
        config_snapshot: build_snapshot(cart_item, price)
      )
    end
  end

  def create_shipping_address(order)
    ShippingAddress.create!(
      order: order,
      city: shipping_address_params[:city],
      district: shipping_address_params[:district],
      apartment_details: shipping_address_params[:apartment_details],
      phone_number: shipping_address_params[:phone_number],
      full_name: shipping_address_params[:full_name]
    )
  end

  def calculate_total_price
    cart.cart_items.sum do |item|
      price = calculate_price_for_item(item)
      (price * item.quantity).round(2)
    end
  end

  def calculate_price_for_item(cart_item)
    PricingCalculator.calculate(
      sellable: cart_item.sellable,
      variant: cart_item.sellable_variant,
      user: user,
      quantity: cart_item.quantity
    )
  end

  def build_snapshot(cart_item, price)
    snapshot = {
      sellable_name: cart_item.sellable.name,
      sellable_type: cart_item.sellable.sellable_type,
      variant_name: cart_item.sellable_variant&.variant_name,
      base_price: cart_item.sellable.base_price,
      final_price: price
    }
    
    # Include service configuration if present
    if cart_item.configuration.present?
      snapshot[:configuration] = cart_item.configuration
    end
    
    snapshot
  end

  def success(order)
    OpenStruct.new(success?: true, order: order, error: nil)
  end

  def failure(message)
    OpenStruct.new(success?: false, order: nil, error: message)
  end

  class ValidationError < StandardError; end
end
