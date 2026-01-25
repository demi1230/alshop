class CreateSpecifications < ActiveRecord::Migration[8.1]
  def change
    create_table :specifications do |t|
      t.references :sellable, null: false, foreign_key: true
      t.references :category_attribute, null: false, foreign_key: true
      t.string :value, null: false

      t.timestamps
    end

    add_index :specifications, [:sellable_id, :category_attribute_id], unique: true, name: 'index_specs_on_sellable_and_attribute'
  end
end
