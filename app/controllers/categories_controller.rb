class CategoriesController < ApplicationController
  def children
    category = Category.find_by(id: params[:id])
    
    unless category
      render json: { error: 'Category not found' }, status: :not_found
      return
    end
    
    authorize category, :show? if defined?(Pundit)
    
    children = category.children.ordered
    render json: children.map { |c| { id: c.id, name: c.name } }
  end
end
