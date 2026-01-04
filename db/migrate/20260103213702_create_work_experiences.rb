class CreateWorkExperiences < ActiveRecord::Migration[8.1]
  def change
    create_table :work_experiences do |t|
      t.references :resume, null: false, foreign_key: true
      t.string :company
      t.string :title
      t.text :description
      t.references :country, null: false, foreign_key: true
      t.references :city, null: false, foreign_key: true
      t.string :starting_month
      t.string :starting_year
      t.string :ending_month
      t.string :ending_year
      t.boolean :is_current
      t.references :jobtype, null: false, foreign_key: true
      t.references :sector, null: false, foreign_key: true
      t.string :monthly_salary

      t.timestamps
    end
  end
end
