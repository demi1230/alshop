class SubscriptionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_subscription, only: [:cancel]

  def index
    @subscriptions = current_user.user_subscriptions.includes(:subscription_plan).paginate(page: params[:page], per_page: 20)
    
    respond_to do |format|
      format.html
      format.json { render json: @subscriptions.as_json(include: :subscription_plan) }
    end
  end

  def create
    @subscription_plan = SubscriptionPlan.find(subscription_params[:subscription_plan_id])
    
    # Parse service config if provided
    service_config = params[:user_subscription][:service_config].present? ? JSON.parse(params[:user_subscription][:service_config]) : nil
    
    @subscription = current_user.user_subscriptions.build(
      subscription_plan: @subscription_plan,
      status: 'active',
      start_date: Date.current,
      end_date: nil
    )

    if @subscription.save
      respond_to do |format|
        format.html { redirect_to subscriptions_path, notice: 'Амжилттай бүртгэгдлээ' }
        format.json { render json: { success: true, subscription: @subscription }, status: :created }
      end
    else
      respond_to do |format|
        format.html { redirect_to subscriptions_path, alert: @subscription.errors.full_messages.join(', ') }
        format.json { render json: { success: false, errors: @subscription.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def cancel
    if @subscription.update(status: 'cancelled', end_date: Date.current)
      respond_to do |format|
        format.html { redirect_to subscriptions_path, notice: 'Цуцлагдлаа' }
        format.json { render json: { success: true } }
      end
    else
      respond_to do |format|
        format.html { redirect_to subscriptions_path, alert: 'Алдаа гарлаа' }
        format.json { render json: { success: false, errors: @subscription.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  private

  def set_subscription
    @subscription = current_user.user_subscriptions.find(params[:id])
  end

  def subscription_params
    params.require(:user_subscription).permit(:subscription_plan_id, :service_config)
  end

  def calculate_next_billing(plan)
    case plan.billing_cycle
    when 'monthly'
      1.month.from_now
    when 'yearly'
      1.year.from_now
    else
      1.month.from_now
    end
  end
end
