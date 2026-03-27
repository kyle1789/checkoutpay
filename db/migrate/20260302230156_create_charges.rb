class CreateCharges < ActiveRecord::Migration[8.0]
  def change
    create_table :charges do |t|
      t.string :idempotency_key
      t.integer :amount_cents
      t.string :currency
      t.string :status
      t.string :provider_charge_id
      t.string :error_message
      t.string :description
      t.timestamps
    end
          add_index :charges, :idempotency_key, unique: true
  end
end
