class CreateAttendees < ActiveRecord::Migration[8.1]
  def change
    create_table :attendees do |t|
      t.references :event, null: false, foreign_key: true
      t.string :firstname
      t.string :lastname
      t.string :company
      t.string :phone
      t.string :email
      t.boolean :paid

      t.timestamps
    end
  end
end
