class Admin::ProductsController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_admin
  before_action :set_product, only: [:edit, :update, :destroy]

  def index
    @products = Product.includes(:sellable, :category, :brand).paginate(page: params[:page], per_page: 20)
    
    respond_to do |format|
      format.html
      format.json { render json: @products.as_json(include: [:sellable, :category, :brand]) }
    end
  end

  def new
    @sellable = Sellable.new(sellable_type: 'Product')
    @product = Product.new
    @categories = Category.where.not(id: Category.joins(:children).select(:id))
    @brands = Brand.all
  end

  def create
    @sellable = Sellable.new(sellable_params)
    @sellable.sellable_type = 'Product'
    
    if @sellable.save
      @product = Product.new(product_params.merge(sellable: @sellable))
      
      if @product.save
        redirect_to admin_products_path, notice: 'Бүтээгдэхүүн үүслээ'
      else
        @sellable.destroy
        @categories = Category.where.not(id: Category.joins(:children).select(:id))
        @brands = Brand.all
        render :new, status: :unprocessable_entity
      end
    else
      @product = Product.new(product_params)
      @categories = Category.where.not(id: Category.joins(:children).select(:id))
      @brands = Brand.all
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @sellable = @product.sellable
    @categories = Category.where.not(id: Category.joins(:children).select(:id))
    @brands = Brand.all
  end

  def update
    @sellable = @product.sellable
    
    if @sellable.update(sellable_params) && @product.update(product_params)
      redirect_to admin_products_path, notice: 'Шинэчлэгдлээ'
    else
      @categories = Category.where.not(id: Category.joins(:children).select(:id))
      @brands = Brand.all
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @product.sellable.destroy
    redirect_to admin_products_path, notice: 'Устгагдлаа'
  end

  private

  def set_product
    @product = Product.find(params[:id])
  end

  def authorize_admin
    unless current_user&.admin?
      redirect_to root_path, alert: 'Админ эрх шаардлагатай'
    end
  end

  def sellable_params
    params.require(:sellable).permit(:name, :base_price, :description, :is_active)
  end

  def product_params
    params.require(:product).permit(:category_id, :brand_id)
  end
end
