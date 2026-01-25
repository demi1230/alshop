class CreateServices < ActiveRecord::Migration[8.1]
  def change
    create_table :services do |t|
      t.references :sellable, null: false, foreign_key: true, index: { unique: true }
      t.references :category, foreign_key: true, null: true
      t.string :service_type, null: false
      t.boolean :requires_schedule, null: false, default: false
      t.text :terms

      t.timestamps
    end
  end
end
