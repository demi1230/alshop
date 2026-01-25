class AddOptionsToServiceConfigSpecs < ActiveRecord::Migration[8.1]
  def change
    add_column :service_config_specs, :options, :json
  end
end
