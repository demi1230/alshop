class CreateProducts < ActiveRecord::Migration[8.1]
  def change
    create_table :products do |t|
      t.references :sellable, null: false, foreign_key: true, index: { unique: true }
      t.references :category, foreign_key: true, null: true
      t.references :brand, foreign_key: true, null: true
      t.string :sku_base

      t.timestamps
    end
  end
end
