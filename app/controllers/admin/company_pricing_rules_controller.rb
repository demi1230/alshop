module Admin
  class CompanyPricingRulesController < BaseController
    def index
      @company_pricing_rules = PricingRule.where.not(company_id: nil)
                                          .includes(:company)
                                          .order(created_at: :desc)
    end
    
    def show
      @rule = PricingRule.find(params[:id])
    end
    
    def new
      @rule = PricingRule.new
    end
    
    def create
      @rule = PricingRule.new(rule_params)
      
      if @rule.save
        redirect_to admin_company_pricing_rules_path, notice: 'Rule created'
      else
        render :new, status: :unprocessable_entity
      end
    end
    
    def edit
      @rule = PricingRule.find(params[:id])
    end
    
    def update
      @rule = PricingRule.find(params[:id])
      
      if @rule.update(rule_params)
        redirect_to admin_company_pricing_rules_path, notice: 'Rule updated'
      else
        render :edit, status: :unprocessable_entity
      end
    end
    
    def destroy
      @rule = PricingRule.find(params[:id])
      @rule.destroy
      redirect_to admin_company_pricing_rules_path, notice: 'Rule deleted'
    end
    
    private
    
    def rule_params
      params.require(:pricing_rule).permit(
        :company_id, :channel, :discount_type, :priority,
        :sellable_id, :sellable_variant_id
      )
    end
  end
end
