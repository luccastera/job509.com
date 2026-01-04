class MakeEducationAndWorkExperienceColumnsNullable < ActiveRecord::Migration[8.1]
  def change
    # Education table
    change_column_null :educations, :country_id, true
    change_column_null :educations, :city_id, true
    change_column_null :educations, :graduation_year, true
    change_column_null :educations, :field_of_study, true

    # Work experiences table
    change_column_null :work_experiences, :sector_id, true
    change_column_null :work_experiences, :jobtype_id, true
    change_column_null :work_experiences, :country_id, true
    change_column_null :work_experiences, :city_id, true
  end
end
