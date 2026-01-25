# frozen_string_literal: true

# AdminPolicy - Controls access to admin namespace
# Only admin users can access admin features
class AdminPolicy < ApplicationPolicy
  def access?
    user&.admin?
  end

  def dashboard?
    access?
  end

  def manage_products?
    access?
  end

  def manage_orders?
    access?
  end

  def view_reports?
    access?
  end
end
