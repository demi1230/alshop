module Admin
  class SubscriptionPlansController < BaseController
    before_action :set_service
    before_action :set_subscription_plan, only: [:edit, :update, :destroy]

    def index
      @subscription_plans = @service.sellable.subscription_plans
    end

    def new
      @subscription_plan = @service.sellable.subscription_plans.build
    end

    def create
      @subscription_plan = @service.sellable.subscription_plans.build(subscription_plan_params)
      
      if @subscription_plan.save
        redirect_to edit_admin_service_path(@service), notice: 'Төлөвлөгөө амжилттай нэмэгдлээ'
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @subscription_plan.update(subscription_plan_params)
        redirect_to edit_admin_service_path(@service), notice: 'Төлөвлөгөө шинэчлэгдлээ'
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @subscription_plan.destroy
      redirect_to edit_admin_service_path(@service), notice: 'Төлөвлөгөө устгагдлаа'
    end

    private

    def set_service
      @service = Service.find(params[:service_id])
    end

    def set_subscription_plan
      @subscription_plan = @service.sellable.subscription_plans.find(params[:id])
    end

    def subscription_plan_params
      params.require(:subscription_plan).permit(
        :name,
        :description,
        :price,
        :billing_cycle,
        :trial_days,
        :is_featured
      )
    end
  end
end
