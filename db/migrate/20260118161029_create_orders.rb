class CreateOrders < ActiveRecord::Migration[8.1]
  def change
    create_table :orders do |t|
      t.references :user, foreign_key: true, null: true
      t.string :status, null: false, default: 'pending'
      t.decimal :total_price, precision: 10, scale: 2, null: false
      t.json :metadata

      t.timestamps
    end

    add_index :orders, :status
  end
end
