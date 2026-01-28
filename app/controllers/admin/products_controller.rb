module Admin
  class ProductsController < BaseController
    before_action :set_product, only: [:show, :edit, :update, :destroy, :toggle_active, :generate_combinations, :update_variants]

    def index
      @products = Product.includes(:sellable, :category, :brand)
      
      # Search
      if params[:q].present?
        @products = @products.search(params[:q])
      end
      
      # Filter by category
      if params[:category_id].present?
        @products = @products.in_category(params[:category_id])
      end
      
      # Filter by brand
      if params[:brand_id].present?
        @products = @products.by_brand(params[:brand_id])
      end
      
      # Filter by status
      case params[:status]
      when 'active'
        @products = @products.active
      when 'inactive'
        @products = @products.inactive
      end
      
      @products = @products.recent.paginate(page: params[:page], per_page: 20)
      
      respond_to do |format|
        format.html
        format.json { render json: @products.as_json(include: [:sellable, :category, :brand]) }
      end
    end
    
    def show
      @sellable = @product.sellable
    end

    def new
      @product = Product.new
      @product.build_sellable(sellable_type: 'Product', is_active: true)
      load_form_data
    end

    def create
      @product = Product.new(product_params)
      
      if @product.save
        redirect_to edit_admin_product_path(@product), notice: 'Бүтээгдэхүүн амжилттай үүслээ'
      else
        load_form_data
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      load_form_data
    end

    def update
      # Handle variant dimensions separately if present
      if params[:product] && params[:product][:variant_dimensions_json].present?
        update_variant_dimensions
        return
      end

      begin
        if @product.update(product_params)
          redirect_to edit_admin_product_path(@product), notice: 'Product updated successfully'
        else
          load_form_data
          render :edit, status: :unprocessable_entity
        end
      rescue => e
        Rails.logger.error "Product update error: #{e.message}"
        Rails.logger.error "Params: #{params.inspect}"
        Rails.logger.error e.backtrace.join("\n")
        load_form_data
        flash.now[:alert] = "Error updating product: #{e.message}"
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      if @product.destroy
        redirect_to admin_products_path, notice: 'Product deleted successfully'
      else
        redirect_to admin_products_path, alert: 'Failed to delete product'
      end
    end
    
    def toggle_active
      @product.sellable.update(is_active: !@product.sellable.is_active)
      
      respond_to do |format|
        format.html { redirect_to admin_products_path, notice: 'Status updated' }
        format.json { render json: { success: true, is_active: @product.sellable.is_active } }
      end
    end
    
    def bulk_update
      product_ids = params[:product_ids] || []
      action = params[:bulk_action]
      
      case action
      when 'activate'
        Sellable.where(id: Product.where(id: product_ids).pluck(:sellable_id))
                .update_all(is_active: true)
        message = 'Products activated'
      when 'deactivate'
        Sellable.where(id: Product.where(id: product_ids).pluck(:sellable_id))
                .update_all(is_active: false)
        message = 'Products deactivated'
      when 'delete'
        Product.where(id: product_ids).destroy_all
        message = 'Products deleted'
      end
      
      redirect_to admin_products_path, notice: message
    end
    
    def reorder
      params[:order].each_with_index do |id, index|
        Product.find(id).update(position: index)
      end
      
      render json: { success: true }
    end

    def generate_combinations
      # Delete default variant if it exists
      default_variant = @product.sellable.sellable_variants.find_by(variant_name: 'Default')
      if default_variant
        default_variant.inventory&.destroy
        default_variant.destroy
      end
      
      combinations = @product.generate_variant_combinations
      created_count = 0
      
      combinations.each do |combo_attrs|
        # Check if this combination already exists
        # SQLite doesn't support @> operator, so we check manually
        existing = @product.sellable.sellable_variants.find do |variant|
          variant.attributes == combo_attrs
        end
        
        next if existing
        
        # Create variant name from combination
        variant_name = combo_attrs.values.join('-')
        
        # Create the variant
        variant = @product.sellable.sellable_variants.create!(
          variant_name: variant_name,
          attributes: combo_attrs,
          is_active: false
        )
        
        # Create inventory
        variant.create_inventory!(quantity: 0)
        created_count += 1
      end
      
      redirect_to edit_admin_product_path(@product), 
                  notice: "Generated #{created_count} new variant combinations (#{combinations.size} total possible)"
    end

    def update_variants
      if @product.update(product_params)
        redirect_to edit_admin_product_path(@product), notice: 'Variants updated successfully'
      else
        load_form_data
        flash.now[:alert] = "Failed to update variants: #{@product.errors.full_messages.join(', ')}"
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def set_product
      @product = Product.includes({ sellable: [:sellable_variants, :specifications] }, :category, :brand).find(params[:id])
    end
    
    def load_form_data
      @categories = Category.roots.includes(children: { children: :children })
      @brands = Brand.all
    end

    def product_params
      params.require(:product).permit(
        :category_id, 
        :brand_id,
        :initial_stock,
        sellable_attributes: [
          :id, :name, :base_price, :is_active, :description, :sellable_type,
          sellable_variants_attributes: [
            :id, :variant_name, :sku, :price_override, :is_active, :_destroy,
            inventory_attributes: [:id, :quantity, :warehouse_id]
          ],
          specifications_attributes: [:id, :category_attribute_id, :value, :_destroy],
          pricing_rules_attributes: [
            :id, :sellable_variant_id, :channel, :discount_type, :value, :priority, 
            :valid_from, :valid_to, :promo_code, :_destroy
          ]
        ]
      )
    end

    def update_variant_dimensions
      # Convert the array format to hash format
      dimensions_json = params[:product][:variant_dimensions_json]
      dimensions_hash = {}
      
      return if dimensions_json.blank?
      
      dimensions_json.each do |_, dimension_data|
        # Skip if dimension_data is not a hash (e.g., it's a string or nil)
        next unless dimension_data.is_a?(Hash) || dimension_data.is_a?(ActionController::Parameters)
        
        # Convert ActionController::Parameters to hash with permit
        if dimension_data.is_a?(ActionController::Parameters)
          dimension_data = dimension_data.permit(:name, values: []).to_h
        end
        
        name = dimension_data[:name] || dimension_data['name']
        values = dimension_data[:values] || dimension_data['values'] || []
        cleaned_values = values.compact.reject(&:blank?)
        dimensions_hash[name] = cleaned_values if name.present? && cleaned_values.any?
      end
      
      if @product.update(variant_dimensions: dimensions_hash)
        # Clean up variants that no longer match the current dimensions
        removed_count = cleanup_invalid_variants(dimensions_hash)
        
        notice_message = 'Variant dimensions saved successfully'
        notice_message += ". Removed #{removed_count} invalid variant(s)" if removed_count > 0
        
        redirect_to edit_admin_product_path(@product), notice: notice_message
      else
        load_form_data
        flash.now[:alert] = "Failed to save variant dimensions: #{@product.errors.full_messages.join(', ')}"
        render :edit, status: :unprocessable_entity
      end
    end
    
    def cleanup_invalid_variants(valid_dimensions)
      return 0 unless @product.sellable&.sellable_variants&.any?
      return 0 if valid_dimensions.blank?
      
      removed_count = 0
      
      @product.sellable.sellable_variants.each do |variant|
        variant_attrs = variant.attributes || {}
        
        # Check if all variant attribute values exist in current dimensions
        should_keep = variant_attrs.all? do |dim_name, dim_value|
          valid_dimensions[dim_name]&.include?(dim_value)
        end
        
        # Also check if variant has all required dimensions
        has_all_dimensions = valid_dimensions.keys.all? do |dim_name|
          variant_attrs.key?(dim_name)
        end
        
        # Remove variant if it doesn't match current dimensions
        unless should_keep && has_all_dimensions
          variant.inventory&.destroy  # Delete inventory first
          variant.destroy
          removed_count += 1
        end
      end
      
      removed_count
    end
  end
end
