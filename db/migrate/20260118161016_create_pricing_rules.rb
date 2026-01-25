class CreatePricingRules < ActiveRecord::Migration[8.1]
  def change
    create_table :pricing_rules do |t|
      t.references :sellable, foreign_key: true, null: true
      t.references :sellable_variant, foreign_key: true, null: true
      t.string :channel, null: false
      t.references :company, foreign_key: true, null: true
      t.bigint :sub_company_id
      t.string :promo_code
      t.string :discount_type, null: false
      t.decimal :value, precision: 10, scale: 2, null: false
      t.datetime :valid_from
      t.datetime :valid_to
      t.integer :priority, null: false, default: 0

      t.timestamps
    end

    add_foreign_key :pricing_rules, :companies, column: :sub_company_id
    add_index :pricing_rules, :channel
    add_index :pricing_rules, :promo_code, where: "promo_code IS NOT NULL"
    add_index :pricing_rules, [:sellable_id, :priority]
    add_index :pricing_rules, [:sellable_variant_id, :priority]
  end
end
