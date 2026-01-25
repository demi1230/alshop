class CreateCarts < ActiveRecord::Migration[8.1]
  def change
    create_table :carts do |t|
      t.references :user, foreign_key: true, null: true
      t.string :session_id
      t.string :status, null: false, default: 'active'
      t.datetime :expires_at

      t.timestamps
    end

    add_index :carts, [:user_id, :status], unique: true, where: "status = 'active' AND user_id IS NOT NULL"
    add_index :carts, :session_id
  end
end
