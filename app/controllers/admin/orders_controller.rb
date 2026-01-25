class Admin::OrdersController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_admin
  before_action :set_order, only: [:show, :mark_paid, :mark_shipped, :cancel]

  def index
    @orders = Order.includes(:user, :order_items).paginate(page: params[:page], per_page: 20)
    @orders = @orders.where(status: params[:status]) if params[:status].present?
    
    respond_to do |format|
      format.html
      format.json { render json: @orders.as_json(include: [:user, :order_items]) }
    end
  end

  def show
    @order_items = @order.order_items.includes(sellable_variant: { sellable: [:brand, product: :category] })
    
    respond_to do |format|
      format.html
      format.json { render json: @order.as_json(include: { order_items: { include: :sellable_variant } }) }
    end
  end

  def mark_paid
    metadata = @order.metadata || {}
    metadata['paid_at'] = Time.current.iso8601
    
    if @order.update(status: 'paid', metadata: metadata)
      respond_to do |format|
        format.html { redirect_to admin_order_path(@order), notice: 'Төлбөр баталгаажлаа' }
        format.json { render json: { success: true, order: @order } }
      end
    else
      respond_to do |format|
        format.html { redirect_to admin_order_path(@order), alert: 'Алдаа гарлаа' }
        format.json { render json: { success: false, errors: @order.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def mark_shipped
    metadata = @order.metadata || {}
    metadata['shipped_at'] = Time.current.iso8601
    metadata['tracking_number'] = params[:tracking_number] if params[:tracking_number]
    
    if @order.update(status: 'shipped', metadata: metadata)
      respond_to do |format|
        format.html { redirect_to admin_order_path(@order), notice: 'Хүргэлтэнд гарлаа' }
        format.json { render json: { success: true, order: @order } }
      end
    else
      respond_to do |format|
        format.html { redirect_to admin_order_path(@order), alert: 'Алдаа гарлаа' }
        format.json { render json: { success: false, errors: @order.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def cancel
    metadata = @order.metadata || {}
    metadata['cancelled_at'] = Time.current.iso8601
    metadata['cancellation_reason'] = params[:cancellation_reason] if params[:cancellation_reason]
    
    if @order.update(status: 'cancelled', metadata: metadata)
      respond_to do |format|
        format.html { redirect_to admin_order_path(@order), notice: 'Цуцлагдлаа' }
        format.json { render json: { success: true, order: @order } }
      end
    else
      respond_to do |format|
        format.html { redirect_to admin_order_path(@order), alert: 'Алдаа гарлаа' }
        format.json { render json: { success: false, errors: @order.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  private

  def set_order
    @order = Order.find(params[:id])
  end

  def authorize_admin
    unless current_user&.admin?
      redirect_to root_path, alert: 'Админ эрх шаардлагатай'
    end
  end
end
