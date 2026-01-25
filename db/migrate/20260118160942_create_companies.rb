class CreateCompanies < ActiveRecord::Migration[8.1]
  def change
    create_table :companies do |t|
      t.string :name, null: false
      t.references :parent_company, foreign_key: { to_table: :companies }, null: true
      t.boolean :is_active, null: false, default: true

      t.timestamps
    end
  end
end
