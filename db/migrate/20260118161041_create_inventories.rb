class CreateInventories < ActiveRecord::Migration[8.1]
  def change
    create_table :inventories do |t|
      t.references :sellable_variant, null: false, foreign_key: true, index: false
      t.integer :quantity, null: false, default: 0
      t.integer :warehouse_id

      t.timestamps
    end

    add_check_constraint :inventories, "quantity >= 0", name: "inventories_quantity_non_negative"
    add_index :inventories, [:sellable_variant_id, :warehouse_id], unique: true, where: "warehouse_id IS NOT NULL", name: "index_inventories_on_variant_and_warehouse"
    add_index :inventories, :sellable_variant_id, unique: true, where: "warehouse_id IS NULL", name: "index_inventories_on_variant_only"
  end
end
