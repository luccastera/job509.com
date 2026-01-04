class CreateResumes < ActiveRecord::Migration[8.1]
  def change
    create_table :resumes do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.text :objective, null: false
      t.string :sex, limit: 1, null: false
      t.string :birth_year, limit: 4, null: false
      t.integer :nationality_id, null: false  # References countries table
      t.references :sector, null: false, foreign_key: true
      t.references :city, foreign_key: true  # Optional
      t.references :country, null: false, foreign_key: true
      t.string :address1
      t.string :address2
      t.string :postal_code, limit: 10
      t.boolean :has_drivers_license, default: false, null: false
      t.integer :years_of_experience, null: false
      t.boolean :is_recommended, default: false, null: false

      t.timestamps
    end

    add_index :resumes, :is_recommended
    add_foreign_key :resumes, :countries, column: :nationality_id
  end
end
