class CreateSellableVariants < ActiveRecord::Migration[8.1]
  def change
    create_table :sellable_variants do |t|
      t.references :sellable, null: false, foreign_key: true
      t.string :sku
      t.string :variant_name, null: false
      t.decimal :price_override, precision: 10, scale: 2
      t.boolean :is_active, null: false, default: true
      t.json :attributes

      t.timestamps
    end

    add_index :sellable_variants, :sku, unique: true, where: "sku IS NOT NULL"
  end
end
