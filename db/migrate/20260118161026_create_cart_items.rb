class CreateCartItems < ActiveRecord::Migration[8.1]
  def change
    create_table :cart_items do |t|
      t.references :cart, null: false, foreign_key: true
      t.references :sellable, null: false, foreign_key: true
      t.references :sellable_variant, foreign_key: true, null: true
      t.integer :quantity, null: false
      t.json :configuration
      t.decimal :line_price_estimate, precision: 10, scale: 2

      t.timestamps
    end

    add_check_constraint :cart_items, "quantity > 0", name: "cart_items_quantity_positive"
  end
end
