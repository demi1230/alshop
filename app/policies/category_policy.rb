class CategoryPolicy < ApplicationPolicy
  # Categories are public for browsing products
  # This policy ensures consistent authorization with ProductPolicy
  
  def show?
    true  # Public catalog - anyone can view categories
  end
  
  # For future admin features
  def create?
    user&.admin?
  end
  
  def update?
    user&.admin?
  end
  
  def destroy?
    user&.admin?
  end
end
