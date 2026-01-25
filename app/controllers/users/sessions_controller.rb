class Users::SessionsController < Devise::SessionsController
  # After sign in, merge session cart to user cart
  def create
    super do |resource|
      merge_session_cart_to_user if session[:cart_id].present?
    end
  end

  private

  def merge_session_cart_to_user
    session_cart = Cart.find_by(id: session[:cart_id])
    return unless session_cart

    user_cart = current_user.carts.active.first_or_create!(
      expires_at: 30.days.from_now,
      status: 'active'
    )

    # Transfer all items from session cart to user cart
    session_cart.cart_items.each do |item|
      existing = user_cart.cart_items.find_by(
        sellable: item.sellable,
        sellable_variant: item.sellable_variant
      )

      if existing
        # Merge quantities
        existing.update!(quantity: existing.quantity + item.quantity)
      else
        # Move item to user cart
        item.update!(cart: user_cart)
      end
    end

    # Clear session cart
    session_cart.destroy
    session.delete(:cart_id)
  end
end
