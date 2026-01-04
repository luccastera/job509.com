class CreateEducations < ActiveRecord::Migration[8.1]
  def change
    create_table :educations do |t|
      t.references :resume, null: false, foreign_key: true
      t.string :diploma
      t.string :school
      t.string :graduation_year
      t.string :field_of_study
      t.references :country, null: false, foreign_key: true
      t.references :city, foreign_key: true
      t.boolean :is_completed
      t.text :comments

      t.timestamps
    end
  end
end
