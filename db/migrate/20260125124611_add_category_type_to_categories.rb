class AddCategoryTypeToCategories < ActiveRecord::Migration[8.1]
  def change
    add_column :categories, :category_type, :string, default: 'both'
    add_index :categories, :category_type
  end
end
