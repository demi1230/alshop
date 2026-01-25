class CreateShippingAddresses < ActiveRecord::Migration[8.1]
  def change
    create_table :shipping_addresses do |t|
      t.references :order, null: false, foreign_key: true
      t.string :city, null: false
      t.string :district
      t.string :apartment_details
      t.string :phone_number, null: false

      t.timestamps
    end
  end
end
