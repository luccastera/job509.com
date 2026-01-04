class CreateListsUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :lists_users do |t|
      t.references :list, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
