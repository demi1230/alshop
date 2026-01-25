class Api::CategoriesController < ApplicationController
  skip_before_action :verify_authenticity_token

  def children
    @category = Category.find(params[:id])
    @children = @category.children
    
    render json: {
      parent: { id: @category.id, name: @category.name },
      children: @children.map { |c| { id: c.id, name: c.name, has_children: c.children.any? } }
    }
  end
end
