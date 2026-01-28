module Admin
  class DiscountsController < BaseController
    def index
      @discounts = PricingRule.where.not(promo_code: nil).order(created_at: :desc)
    end
    
    def show
      @discount = PricingRule.find(params[:id])
    end
    
    def new
      @discount = PricingRule.new
    end
    
    def create
      @discount = PricingRule.new(discount_params)
      
      if @discount.save
        redirect_to admin_discounts_path, notice: 'Discount created'
      else
        render :new, status: :unprocessable_entity
      end
    end
    
    def edit
      @discount = PricingRule.find(params[:id])
    end
    
    def update
      @discount = PricingRule.find(params[:id])
      
      if @discount.update(discount_params)
        redirect_to admin_discounts_path, notice: 'Discount updated'
      else
        render :edit, status: :unprocessable_entity
      end
    end
    
    def destroy
      @discount = PricingRule.find(params[:id])
      @discount.destroy
      redirect_to admin_discounts_path, notice: 'Discount deleted'
    end
    
    def toggle_active
      @discount = PricingRule.find(params[:id])
      @discount.update!(is_active: !@discount.is_active)
      
      render json: { success: true, is_active: @discount.is_active }
    end
    
    private
    
    def discount_params
      params.require(:pricing_rule).permit(
        :channel, :discount_type, :priority, :promo_code,
        :sellable_id, :sellable_variant_id, :company_id
      )
    end
  end
end
