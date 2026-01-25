# frozen_string_literal: true

# ProductPolicy - Controls access to products
# Rails convention: Everyone can view, only admins can manage
class ProductPolicy < ApplicationPolicy
  # Scope for listing products
  class Scope < ApplicationPolicy::Scope
    def resolve
      # Everyone sees active products, admins see all
      if user&.admin?
        scope.all
      else
        scope.active
      end
    end
  end

  # Anyone can view active products
  def index?
    true
  end

  # Anyone can view a product
  def show?
    true
  end

  # Only admins can create products
  def create?
    user&.admin?
  end

  # Only admins can update products
  def update?
    user&.admin?
  end

  # Only admins can delete products
  def destroy?
    user&.admin?
  end

  # Only admins can see inactive products
  def show_inactive?
    user&.admin?
  end
end
