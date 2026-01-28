module Admin
  class UsersController < BaseController
    def index
      @users = User.all.order(created_at: :desc)
                  .page(params[:page])
                  .per(20)
    end
    
    def show
      @user = User.find(params[:id])
    end
    
    def edit
      @user = User.find(params[:id])
    end
    
    def update
      @user = User.find(params[:id])
      
      if @user.update(user_params)
        redirect_to admin_users_path, notice: 'User updated'
      else
        render :edit, status: :unprocessable_entity
      end
    end
    
    def toggle_active
      @user = User.find(params[:id])
      # Assuming there's an active field or similar
      # @user.update!(active: !@user.active)
      
      render json: { success: true }
    end
    
    private
    
    def user_params
      params.require(:user).permit(:email, :role, :company_id)
    end
  end
end
