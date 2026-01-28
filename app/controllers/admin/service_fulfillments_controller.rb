module Admin
  class ServiceFulfillmentsController < BaseController
    def index
      @fulfillments = ServiceFulfillment.includes(:order_item, :assigned_user)
                                       .order(created_at: :desc)
                                       .page(params[:page])
                                       .per(20)
    end
    
    def show
      @fulfillment = ServiceFulfillment.find(params[:id])
    end
    
    def update
      @fulfillment = ServiceFulfillment.find(params[:id])
      
      if @fulfillment.update(fulfillment_params)
        redirect_to admin_service_fulfillment_path(@fulfillment), notice: 'Fulfillment updated'
      else
        redirect_to admin_service_fulfillment_path(@fulfillment), alert: 'Update failed'
      end
    end
    
    def assign
      @fulfillment = ServiceFulfillment.find(params[:id])
      @fulfillment.update!(
        assigned_user_id: params[:user_id],
        status: 'assigned'
      )
      
      render json: { success: true }
    end
    
    def complete
      @fulfillment = ServiceFulfillment.find(params[:id])
      @fulfillment.update!(status: 'completed')
      
      render json: { success: true }
    end
    
    private
    
    def fulfillment_params
      params.require(:service_fulfillment).permit(:status, :assigned_user_id, :notes)
    end
  end
end
