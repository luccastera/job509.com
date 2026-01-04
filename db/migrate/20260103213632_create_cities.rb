class CreateCities < ActiveRecord::Migration[8.1]
  def change
    create_table :cities do |t|
      t.string :name
      t.references :country, null: false, foreign_key: true
      t.string :latitude
      t.string :longitude

      t.timestamps
    end
  end
end
