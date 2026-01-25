class CreateSellables < ActiveRecord::Migration[8.1]
  def change
    create_table :sellables do |t|
      t.string :name, null: false
      t.string :sellable_type, null: false
      t.decimal :base_price, precision: 10, scale: 2, null: false
      t.boolean :is_active, null: false, default: true
      t.text :description

      t.timestamps
    end

    add_index :sellables, :sellable_type
  end
end
