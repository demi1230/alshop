class Admin::PricingRulesController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_admin
  before_action :set_pricing_rule, only: [:edit, :update, :destroy]

  def index
    @pricing_rules = PricingRule.includes(:sellable, :company).paginate(page: params[:page], per_page: 20)
    
    respond_to do |format|
      format.html
      format.json { render json: @pricing_rules.as_json(include: [:sellable, :company]) }
    end
  end

  def new
    @pricing_rule = PricingRule.new
    @sellables = Sellable.active
    @companies = Company.all
  end

  def create
    @pricing_rule = PricingRule.new(pricing_rule_params)
    
    if @pricing_rule.save
      redirect_to admin_pricing_rules_path, notice: 'Үнийн дүрэм үүслээ'
    else
      @sellables = Sellable.active
      @companies = Company.all
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @sellables = Sellable.active
    @companies = Company.all
  end

  def update
    if @pricing_rule.update(pricing_rule_params)
      redirect_to admin_pricing_rules_path, notice: 'Шинэчлэгдлээ'
    else
      @sellables = Sellable.active
      @companies = Company.all
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @pricing_rule.destroy
    redirect_to admin_pricing_rules_path, notice: 'Устгагдлаа'
  end

  private

  def set_pricing_rule
    @pricing_rule = PricingRule.find(params[:id])
  end

  def authorize_admin
    unless current_user&.admin?
      redirect_to root_path, alert: 'Админ эрх шаардлагатай'
    end
  end

  def pricing_rule_params
    params.require(:pricing_rule).permit(
      :sellable_id, :sellable_variant_id, :company_id, :channel, 
      :discount_type, :value, :priority, :promo_code, 
      :valid_from, :valid_to
    )
  end
end
