class MakeResumeColumnsNullable < ActiveRecord::Migration[8.1]
  def change
    change_column_null :resumes, :objective, true
    change_column_null :resumes, :birth_year, true
    change_column_null :resumes, :nationality_id, true
    change_column_null :resumes, :sector_id, true
    change_column_null :resumes, :country_id, true
    change_column_null :resumes, :years_of_experience, true
  end
end
