class CreateServiceConfigSpecs < ActiveRecord::Migration[8.1]
  def change
    create_table :service_config_specs do |t|
      t.references :service, null: false, foreign_key: true
      t.string :field_name, null: false
      t.string :data_type, null: false
      t.decimal :unit_price, precision: 10, scale: 2, null: false, default: 0.0
      t.text :description

      t.timestamps
    end
  end
end
