class CreateSubscriptionPlans < ActiveRecord::Migration[8.1]
  def change
    create_table :subscription_plans do |t|
      t.references :sellable, null: false, foreign_key: true
      t.references :company, foreign_key: true, null: true
      t.string :billing_cycle, null: false
      t.decimal :price, precision: 10, scale: 2, null: false
      t.integer :trial_days, null: false, default: 0

      t.timestamps
    end
  end
end
