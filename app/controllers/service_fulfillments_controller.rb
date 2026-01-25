class ServiceFulfillmentsController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_staff
  before_action :set_service_fulfillment, only: [:show, :update]

  def index
    @service_fulfillments = policy_scope(ServiceFulfillment).includes(:order_item, :assigned_user)
      .paginate(page: params[:page], per_page: 20)
    
    # Filter by status if provided
    @service_fulfillments = @service_fulfillments.where(status: params[:status]) if params[:status].present?
    
    respond_to do |format|
      format.html
      format.json { render json: @service_fulfillments.as_json(include: [:order_item, :assigned_user]) }
    end
  end

  def show
    respond_to do |format|
      format.html
      format.json { render json: @service_fulfillment.as_json(include: [:order_item, :assigned_user]) }
    end
  end

  def update
    action = fulfillment_params[:action]
    
    case action
    when 'assign'
      if @service_fulfillment.update(assigned_user: current_user, status: 'ongoing')
        respond_success('Томилогдлоо')
      else
        respond_error
      end
    when 'complete'
      @service_fulfillment.completed_at = Time.current
      @service_fulfillment.completion_notes = fulfillment_params[:completion_notes]
      
      if @service_fulfillment.update(status: 'completed')
        respond_success('Дууслаа')
      else
        respond_error
      end
    when 'cancel'
      if @service_fulfillment.update(status: 'cancelled')
        respond_success('Цуцлагдлаа')
      else
        respond_error
      end
    else
      if @service_fulfillment.update(fulfillment_params.except(:action))
        respond_success('Шинэчлэгдлээ')
      else
        respond_error
      end
    end
  end

  private

  def set_service_fulfillment
    @service_fulfillment = ServiceFulfillment.find(params[:id])
  end

  def authorize_staff
    unless current_user&.staff? || current_user&.admin?
      redirect_to root_path, alert: 'Эрх хүрэхгүй байна'
    end
  end

  def fulfillment_params
    params.require(:service_fulfillment).permit(:status, :action, :notes, :scheduled_at)
  end

  def respond_success(message)
    respond_to do |format|
      format.html { redirect_to service_fulfillments_path, notice: message }
      format.json { render json: { success: true, service_fulfillment: @service_fulfillment } }
    end
  end

  def respond_error
    respond_to do |format|
      format.html { redirect_to service_fulfillments_path, alert: @service_fulfillment.errors.full_messages.join(', ') }
      format.json { render json: { success: false, errors: @service_fulfillment.errors.full_messages }, status: :unprocessable_entity }
    end
  end
end
