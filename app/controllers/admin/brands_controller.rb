class Admin::BrandsController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_admin
  before_action :set_brand, only: [:edit, :update, :destroy]

  def index
    @brands = Brand.all.paginate(page: params[:page], per_page: 20)
    
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
      redirect_to admin_brands_path, notice: 'Брэнд үүслээ'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @brand.update(brand_params)
      redirect_to admin_brands_path, notice: 'Шинэчлэгдлээ'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @brand.products.any?
      redirect_to admin_brands_path, alert: 'Бүтээгдэхүүн байгаа тул устгах боломжгүй'
    else
      @brand.destroy
      redirect_to admin_brands_path, notice: 'Устгагдлаа'
    end
  end

  private

  def set_brand
    @brand = Brand.find(params[:id])
  end

  def authorize_admin
    unless current_user&.admin?
      redirect_to root_path, alert: 'Админ эрх шаардлагатай'
    end
  end

  def brand_params
    params.require(:brand).permit(:name)
  end
end
