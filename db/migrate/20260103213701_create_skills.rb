class CreateSkills < ActiveRecord::Migration[8.1]
  def change
    create_table :skills do |t|
      t.references :resume, null: false, foreign_key: true
      t.string :description

      t.timestamps
    end
  end
end
