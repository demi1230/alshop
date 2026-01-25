class CreateOrderItems < ActiveRecord::Migration[8.1]
  def change
    create_table :order_items do |t|
      t.references :order, null: false, foreign_key: true
      t.references :sellable, null: false, foreign_key: true
      t.references :sellable_variant, foreign_key: true, null: true
      t.integer :quantity, null: false
      t.decimal :price_at_purchase, precision: 10, scale: 2, null: false
      t.decimal :line_total, precision: 10, scale: 2, null: false
      t.json :config_snapshot

      t.timestamps
    end

    add_check_constraint :order_items, "quantity > 0", name: "order_items_quantity_positive"
  end
end
