class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  # Pundit authorization
  include Pundit::Authorization

  # Handle authorization errors
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  # Strong parameters for Devise
  before_action :configure_permitted_parameters, if: :devise_controller?

  # Make current_cart available in views
  helper_method :current_cart

  private

  # Get or create current cart (session-based for guests, user-based for logged in users)
  def current_cart
    if user_signed_in?
      @current_cart ||= current_user.carts.active.first_or_create!(
        expires_at: 30.days.from_now,
        status: 'active'
      )
    else
      @current_cart ||= begin
        if session[:cart_id]
          Cart.find_by(id: session[:cart_id])
        end
        
        unless @current_cart&.persisted?
          @current_cart = Cart.create!(
            expires_at: 30.days.from_now,
            status: 'active'
          )
          session[:cart_id] = @current_cart.id
        end
        
        @current_cart
      end
    end
  end

  def user_not_authorized
    flash[:alert] = "You are not authorized to perform this action."
    redirect_back(fallback_location: root_path)
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:email])
    devise_parameter_sanitizer.permit(:account_update, keys: [:email])
  end
end
