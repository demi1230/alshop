module Admin
  class CategoryAttributesController < BaseController
    before_action :set_category
    before_action :set_category_attribute, only: [:edit, :update, :destroy]

    def index
      @category_attributes = @category.category_attributes.order(:name)
    end

    def new
      @category_attribute = @category.category_attributes.build
    end

    def create
      @category_attribute = @category.category_attributes.build(category_attribute_params)
      
      if @category_attribute.save
        redirect_to admin_category_category_attributes_path(@category), notice: 'Attribute created successfully'
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @category_attribute.update(category_attribute_params)
        redirect_to admin_category_category_attributes_path(@category), notice: 'Attribute updated successfully'
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      if @category_attribute.destroy
        redirect_to admin_category_category_attributes_path(@category), notice: 'Attribute deleted successfully'
      else
        redirect_to admin_category_category_attributes_path(@category), alert: 'Failed to delete attribute'
      end
    end

    private

    def set_category
      @category = Category.find(params[:category_id])
    end

    def set_category_attribute
      @category_attribute = @category.category_attributes.find(params[:id])
    end

    def category_attribute_params
      params.require(:category_attribute).permit(:name, :is_required)
    end
  end
end
