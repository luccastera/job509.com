class CreateFeaturedRecruiters < ActiveRecord::Migration[8.1]
  def change
    create_table :featured_recruiters do |t|
      t.string :name
      t.string :website_url

      t.timestamps
    end
  end
end
