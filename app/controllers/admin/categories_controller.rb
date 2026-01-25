class Admin::CategoriesController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_admin
  before_action :set_category, only: [:edit, :update, :destroy]

  def index
    @categories = Category.roots.includes(:children)
    
    respond_to do |format|
      format.html
      format.json { render json: @categories.as_json(include: :children) }
    end
  end

  def new
    @category = Category.new
    @parent_categories = Category.all
  end

  def create
    @category = Category.new(category_params)
    
    if @category.save
      redirect_to admin_categories_path, notice: 'Категори үүслээ'
    else
      @parent_categories = Category.all
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @parent_categories = Category.where.not(id: [@category.id] + @category.descendant_ids)
  end

  def update
    if @category.update(category_params)
      redirect_to admin_categories_path, notice: 'Шинэчлэгдлээ'
    else
      @parent_categories = Category.where.not(id: [@category.id] + @category.descendant_ids)
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @category.children.any?
      redirect_to admin_categories_path, alert: 'Дэд категори байгаа тул устгах боломжгүй'
    elsif @category.products.any? || @category.services.any?
      redirect_to admin_categories_path, alert: 'Бүтээгдэхүүн эсвэл үйлчилгээ байгаа тул устгах боломжгүй'
    else
      @category.destroy
      redirect_to admin_categories_path, notice: 'Устгагдлаа'
    end
  end

  private

  def set_category
    @category = Category.find(params[:id])
  end

  def authorize_admin
    unless current_user&.admin?
      redirect_to root_path, alert: 'Админ эрх шаардлагатай'
    end
  end

  def category_params
    params.require(:category).permit(:name, :parent_id)
  end
end
