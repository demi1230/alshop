module Admin
  class ServicesController < BaseController
    before_action :set_service, only: [:show, :edit, :update, :destroy, :toggle_active]

    def index
      @services = Service.includes(:sellable, :category)
      @categories = Category.all.order(:name)
      
      # Search
      if params[:q].present?
        @services = @services.joins(:sellable).where('sellables.name LIKE ?', "%#{params[:q]}%")
      end
      
      # Filter by category
      if params[:category_id].present?
        @services = @services.where(category_id: params[:category_id])
      end
      
      # Filter by service type
      if params[:service_type].present?
        @services = @services.where(service_type: params[:service_type])
      end
      
      # Filter by status
      case params[:status]
      when 'active'
        @services = @services.joins(:sellable).where(sellables: { is_active: true })
      when 'inactive'
        @services = @services.joins(:sellable).where(sellables: { is_active: false })
      end
      
      @services = @services.order(created_at: :desc).paginate(page: params[:page], per_page: 20)
      
      respond_to do |format|
        format.html
        format.json { render json: @services.as_json(include: [:sellable, :category]) }
      end
    end
    
    def show
      @sellable = @service.sellable
    end

    def new
      @service = Service.new
      @service.build_sellable(sellable_type: 'Service', is_active: true)
      load_form_data
    end

    def create
      @service = Service.new(service_params)
      
      if @service.save
        redirect_to edit_admin_service_path(@service), notice: 'Service created successfully'
      else
        load_form_data
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      load_form_data
    end

    def update
      if @service.update(service_params)
        redirect_to edit_admin_service_path(@service), notice: 'Service updated successfully'
      else
        load_form_data
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      if @service.destroy
        redirect_to admin_services_path, notice: 'Service deleted successfully'
      else
        redirect_to admin_services_path, alert: 'Failed to delete service'
      end
    end
    
    def toggle_active
      @service.sellable.update(is_active: !@service.sellable.is_active)
      
      respond_to do |format|
        format.html { redirect_to admin_services_path, notice: 'Status updated' }
        format.json { render json: { success: true, is_active: @service.sellable.is_active } }
      end
    end
    
    def bulk_action
      service_ids = params[:service_ids] || []
      action = params[:bulk_action]
      
      case action
      when 'activate'
        Sellable.where(id: Service.where(id: service_ids).pluck(:sellable_id))
                .update_all(is_active: true)
        message = 'Services activated'
      when 'deactivate'
        Sellable.where(id: Service.where(id: service_ids).pluck(:sellable_id))
                .update_all(is_active: false)
        message = 'Services deactivated'
      when 'delete'
        Service.where(id: service_ids).destroy_all
        message = 'Services deleted'
      end
      
      redirect_to admin_services_path, notice: message
    end
    
    private
    
    def set_service
      @service = Service.includes({ sellable: [:specifications] }, :category).find(params[:id])
    end
    
    def load_form_data
      @categories = Category.roots.includes(children: { children: :children })
      @category_attributes = @service&.category ? @service.category.category_attributes.order(:id) : []
    end
    
    def service_params
      params.require(:service).permit(
        :category_id,
        :service_type,
        :requires_schedule,
        :terms,
        sellable_attributes: [
          :id, :name, :base_price, :is_active, :description, :sellable_type,
          specifications_attributes: [:id, :category_attribute_id, :value, :_destroy],
          pricing_rules_attributes: [
            :id, :sellable_variant_id, :channel, :discount_type, :value, :priority, 
            :valid_from, :valid_to, :promo_code, :_destroy
          ]
        ]
      )
    end
  end
end
