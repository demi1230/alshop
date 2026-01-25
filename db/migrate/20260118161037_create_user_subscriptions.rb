class CreateUserSubscriptions < ActiveRecord::Migration[8.1]
  def change
    create_table :user_subscriptions do |t|
      t.references :user, null: false, foreign_key: true
      t.references :subscription_plan, null: false, foreign_key: true
      t.date :start_date, null: false
      t.date :end_date
      t.string :status, null: false

      t.timestamps
    end

    add_index :user_subscriptions, [:user_id, :status]
  end
end
