class CreateShareTokens < ActiveRecord::Migration[8.1]
  def change
    create_table :share_tokens do |t|
      t.references :resume, null: false, foreign_key: true
      t.string :token, null: false
      t.integer :expires_in, default: 7, null: false  # Days until expiration

      t.timestamps
    end

    add_index :share_tokens, :token, unique: true
  end
end
