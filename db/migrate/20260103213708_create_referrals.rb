class CreateReferrals < ActiveRecord::Migration[8.1]
  def change
    create_table :referrals do |t|
      t.references :resume, null: false, foreign_key: true
      t.string :firstname
      t.string :lastname
      t.string :phone
      t.string :email
      t.string :relationship
      t.boolean :is_verified
      t.text :admin_comments

      t.timestamps
    end
  end
end
