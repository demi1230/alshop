class CreateServiceFulfillments < ActiveRecord::Migration[8.1]
  def change
    create_table :service_fulfillments do |t|
      t.references :order_item, null: false, foreign_key: true
      t.references :assigned_user, foreign_key: { to_table: :users }, null: true
      t.datetime :scheduled_at
      t.string :status, null: false, default: 'scheduled'
      t.json :result

      t.timestamps
    end

    add_index :service_fulfillments, :status
  end
end
