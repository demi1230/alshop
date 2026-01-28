module Admin
  class BrandsController < BaseController
    before_action :set_brand, only: [:edit, :update, :destroy]

    def index
      @brands = Brand.all
      
      # Search
      if params[:q].present?
        @brands = @brands.where('name LIKE ?', "%#{params[:q]}%")
      end
      
      @brands = @brands.order(created_at: :desc).paginate(page: params[:page], per_page: 20)
      
      respond_to do |format|
        format.html
        format.json { render json: @brands }
      end
    end

    def new
      @brand = Brand.new
    end

    def create
      @brand = Brand.new(brand_params)
      
      if @brand.save
        redirect_to edit_admin_brand_path(@brand), notice: 'Брэнд амжилттай үүслээ'
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @brand.update(brand_params)
        redirect_to edit_admin_brand_path(@brand), notice: 'Брэнд шинэчлэгдлээ'
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      if @brand.products.any?
        redirect_to admin_brands_path, alert: 'Бүтээгдэхүүн байгаа тул устгах боломжгүй'
      else
        @brand.destroy
        redirect_to admin_brands_path, notice: 'Брэнд устгагдлаа'
      end
    end

    def bulk_action
      brand_ids = params[:brand_ids]
      action = params[:action_type]

      case action
      when 'delete'
        Brand.where(id: brand_ids).destroy_all
        message = 'Брэндүүд устгагдлаа'
      end

      redirect_to admin_brands_path, notice: message
    end

    private

    def set_brand
      @brand = Brand.find(params[:id])
    end

    def brand_params
      params.require(:brand).permit(:name, :website_url)
    end
  end
end
