class CreateEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :events do |t|
      t.string :name
      t.text :description
      t.datetime :starts_at
      t.datetime :ends_at
      t.string :location
      t.string :youtube_url
      t.integer :cost

      t.timestamps
    end
  end
end
