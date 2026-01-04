class CreateCoupons < ActiveRecord::Migration[8.1]
  def change
    create_table :coupons do |t|
      t.string :code
      t.integer :value
      t.string :comment
      t.references :administrator, null: false, foreign_key: true

      t.timestamps
    end
  end
end
