class CreateCategoryAttributes < ActiveRecord::Migration[8.1]
  def change
    create_table :category_attributes do |t|
      t.references :category, null: false, foreign_key: true
      t.string :name, null: false
      t.string :unit
      t.boolean :is_required, null: false, default: false

      t.timestamps
    end
  end
end
