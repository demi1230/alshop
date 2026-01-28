module Admin
  class ServiceConfigSpecsController < BaseController
    before_action :set_service
    before_action :set_service_config_spec, only: [:edit, :update, :destroy]

    def index
      @service_config_specs = @service.service_config_specs
    end

    def new
      @service_config_spec = @service.service_config_specs.build
    end

    def create
      @service_config_spec = @service.service_config_specs.build(service_config_spec_params)
      
      # Build options JSON from form arrays
      if params[:option_values].present?
        options_array = []
        params[:option_values].each_with_index do |value, index|
          price = params[:option_prices][index].to_f
          options_array << { "value" => value, "price" => price }
        end
        @service_config_spec.options = options_array.to_json
      end
      
      if @service_config_spec.save
        redirect_to edit_admin_service_path(@service), notice: 'Тохиргоо амжилттай нэмэгдлээ'
      else
        Rails.logger.error "ServiceConfigSpec validation errors: #{@service_config_spec.errors.full_messages.join(', ')}"
        flash.now[:alert] = "Алдаа: #{@service_config_spec.errors.full_messages.join(', ')}"
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      # Build options JSON from form arrays
      if params[:option_values].present?
        options_array = []
        params[:option_values].each_with_index do |value, index|
          price = params[:option_prices][index].to_f
          options_array << { "value" => value, "price" => price }
        end
        @service_config_spec.options = options_array.to_json
      end
      
      if @service_config_spec.update(service_config_spec_params)
        redirect_to edit_admin_service_path(@service), notice: 'Тохиргоо шинэчлэгдлээ'
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @service_config_spec.destroy
      redirect_to edit_admin_service_path(@service), notice: 'Тохиргоо устгагдлаа'
    end

    private

    def set_service
      @service = Service.find(params[:service_id])
    end

    def set_service_config_spec
      @service_config_spec = @service.service_config_specs.find(params[:id])
    end

    def service_config_spec_params
      params.require(:service_config_spec).permit(
        :field_name,
        :description,
        :data_type,
        :required,
        :default_value,
        :unit_price
      )
    end

    # These params are outside the service_config_spec namespace
    def permitted_params
      params.permit(option_values: [], option_prices: [])
    end
  end
end
