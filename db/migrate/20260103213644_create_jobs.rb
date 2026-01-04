class CreateJobs < ActiveRecord::Migration[8.1]
  def change
    create_table :jobs do |t|
      t.string :title, null: false
      t.string :company, null: false
      t.string :company_url
      t.text :company_description
      t.text :description, null: false
      t.text :qualifications, null: false
      t.references :user, null: false, foreign_key: true
      t.references :jobtype, null: false, foreign_key: true
      t.references :sector, null: false, foreign_key: true
      t.references :country, null: false, foreign_key: true
      t.references :city, foreign_key: true  # Optional
      t.boolean :approved, default: false, null: false
      t.boolean :expired, default: false, null: false
      t.date :post_date, null: false
      t.string :apply_url
      t.float :payment_amount
      t.string :payment_type
      t.date :payment_date
      t.text :payment_comment

      t.timestamps
    end

    add_index :jobs, :approved
    add_index :jobs, :expired
    add_index :jobs, :post_date
  end
end
