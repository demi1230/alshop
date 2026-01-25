class AddDeviseToUsers < ActiveRecord::Migration[8.1]
  def change
    # Remove has_secure_password column
    remove_column :users, :password_digest, :string if column_exists?(:users, :password_digest)

    # Add Devise columns
    add_column :users, :encrypted_password, :string, null: false, default: "" unless column_exists?(:users, :encrypted_password)
    
    ## Recoverable
    add_column :users, :reset_password_token, :string unless column_exists?(:users, :reset_password_token)
    add_column :users, :reset_password_sent_at, :datetime unless column_exists?(:users, :reset_password_sent_at)

    ## Rememberable
    add_column :users, :remember_created_at, :datetime unless column_exists?(:users, :remember_created_at)

    # Indexes
    add_index :users, :reset_password_token, unique: true unless index_exists?(:users, :reset_password_token)
  end
end
