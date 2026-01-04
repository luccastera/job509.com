class CreateApplics < ActiveRecord::Migration[8.1]
  def change
    create_table :applics do |t|
      t.references :job, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.text :cover_letter
      t.boolean :hidden, default: false, null: false
      t.boolean :star, default: false, null: false

      t.timestamps
    end

    add_index :applics, [:job_id, :user_id], unique: true
  end
end
