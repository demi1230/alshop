module Admin
  class PricingRulesController < BaseController
    before_action :set_pricing_rule, only: [:edit, :update, :destroy]

    def index
      @pricing_rules = PricingRule.includes(:sellable, :company).order(priority: :desc, created_at: :desc)
      
      # Search by sellable name or promo code
      if params[:search].present?
        search_term = "%#{params[:search]}%"
        @pricing_rules = @pricing_rules.left_joins(:sellable).where(
          "sellables.name LIKE ? OR pricing_rules.promo_code LIKE ?", 
          search_term, search_term
        )
      end
      
      # Filter by channel
      if params[:channel].present? && params[:channel] != 'all'
        @pricing_rules = @pricing_rules.where(channel: params[:channel])
      end
      
      # Filter by discount_type
      if params[:discount_type].present? && params[:discount_type] != 'all'
        @pricing_rules = @pricing_rules.where(discount_type: params[:discount_type])
      end
      
      # Filter by status (active/expired)
      if params[:status].present?
        case params[:status]
        when 'active'
          @pricing_rules = @pricing_rules.active
        when 'expired'
          @pricing_rules = @pricing_rules.where('valid_to < ?', Time.current)
        end
      end
      
      @pricing_rules = @pricing_rules.paginate(page: params[:page], per_page: 20)
      
      respond_to do |format|
        format.html
        format.json { render json: @pricing_rules.as_json(include: [:sellable, :company]) }
      end
    end

    def new
      @pricing_rule = PricingRule.new(priority: 10)
      load_form_data
    end

    def create
      @pricing_rule = PricingRule.new(pricing_rule_params)
      
      if @pricing_rule.save
        redirect_to edit_admin_pricing_rule_path(@pricing_rule), notice: 'Үнийн дүрэм үүслээ'
      else
        load_form_data
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      load_form_data
    end

    def update
      if @pricing_rule.update(pricing_rule_params)
        redirect_to admin_pricing_rules_path, notice: 'Шинэчлэгдлээ'
      else
        load_form_data
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @pricing_rule.destroy
      redirect_to admin_pricing_rules_path, notice: 'Устгагдлаа'
    end
    
    def bulk_action
      ids = params[:ids] || []
      action = params[:bulk_action]
      
      case action
      when 'delete'
        PricingRule.where(id: ids).destroy_all
        flash[:notice] = "#{ids.length} үнийн дүрэм устгалаа"
      end
      
      redirect_to admin_pricing_rules_path
    end

    private

    def set_pricing_rule
      @pricing_rule = PricingRule.find(params[:id])
    end
    
    def load_form_data
      @sellables = Sellable.includes(:product, :service).order(:name)
      @companies = Company.where(is_active: true).order(:name)
    end

    def pricing_rule_params
      params.require(:pricing_rule).permit(
        :sellable_id, :sellable_variant_id, :company_id, :channel, 
        :discount_type, :value, :priority, :promo_code, 
        :valid_from, :valid_to
      )
    end
  end
end
