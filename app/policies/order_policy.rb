# frozen_string_literal: true

# OrderPolicy - Controls access to orders
# Rails convention: Users can only see their own orders, admins see all
class OrderPolicy < ApplicationPolicy
  # Scope for listing orders
  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.admin?
        # Admins see all orders
        scope.all
      else
        # Customers see only their own orders
        scope.where(user: user)
      end
    end
  end

  # Anyone authenticated can create an order
  def create?
    user.present?
  end

  # Users can view their own orders, admins can view all
  def show?
    user.admin? || record.user_id == user.id
  end

  # Only users can view their own orders
  def index?
    user.present?
  end

  # Admins can update order status
  def update?
    user.admin?
  end

  # Admins can mark orders as paid
  def mark_as_paid?
    user.admin?
  end

  # Admins can mark orders as shipped
  def mark_as_shipped?
    user.admin?
  end

  # Users can cancel their own pending orders, admins can cancel any
  def cancel?
    return false unless record.can_be_cancelled?
    user.admin? || record.user_id == user.id
  end

  # Admins can refund orders
  def refund?
    user.admin?
  end
end
