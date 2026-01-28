class AddRequiredAndDefaultValueToServiceConfigSpecs < ActiveRecord::Migration[8.1]
  def change
    add_column :service_config_specs, :required, :boolean
    add_column :service_config_specs, :default_value, :string
  end
end
