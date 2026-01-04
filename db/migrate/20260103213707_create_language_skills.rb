class CreateLanguageSkills < ActiveRecord::Migration[8.1]
  def change
    create_table :language_skills do |t|
      t.references :resume, null: false, foreign_key: true
      t.references :language, null: false, foreign_key: true
      t.integer :speaking_level
      t.integer :writing_level

      t.timestamps
    end
  end
end
