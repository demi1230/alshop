module Admin
  class BaseController < ActionController::Base
    # Include necessary modules for standalone operation
    include ActionController::Helpers
    include ActionController::Cookies
    include ActionController::RequestForgeryProtection
    include ActionController::Flash
    
    # Include Devise helpers for authentication
    include Devise::Controllers::Helpers
    
    # CSRF protection
    protect_from_forgery with: :exception
    
    # Helper path for admin helpers
    helper :all
    helper AdminHelper
    
    # Devise authentication
    before_action :authenticate_user!
    before_action :ensure_admin!
    
    layout 'admin'
    
    def index
      # Admin landing page showing all sections
    end
    
    private
    
    # Ensure the current user is an admin
    def ensure_admin!
      unless current_user&.admin?
        redirect_to root_path, alert: 'Access denied. Admin privileges required.'
      end
    end
    
    # Set flash message for successful actions
    def set_success_message(message = 'Operation completed successfully')
      flash[:notice] = message
    end
    
    # Set flash message for errors
    def set_error_message(message = 'An error occurred')
      flash[:alert] = message
    end
    
    # Render JSON error response
    def render_error(message, status: :unprocessable_entity)
      render json: { error: message }, status: status
    end
    
    # Render JSON success response
    def render_success(message = 'Success', data: nil)
      render json: { message: message, data: data }, status: :ok
    end
  end
end
