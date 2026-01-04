class CreateAdministrators < ActiveRecord::Migration[8.1]
  def change
    create_table :administrators do |t|
      t.string :name, null: false
      t.string :password_digest, null: false
      t.integer :role, default: 0, null: false  # enum: regular = 0, super = 1

      t.timestamps
    end

    add_index :administrators, :name, unique: true
  end
end
