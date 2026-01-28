class AddVariantDimensionsToProducts < ActiveRecord::Migration[8.1]
  def change
    add_column :products, :variant_dimensions, :json
  end
end
