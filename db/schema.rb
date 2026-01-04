# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_01_04_022309) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "administrators", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.string "password_digest", null: false
    t.integer "role", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_administrators_on_name", unique: true
  end

  create_table "applics", force: :cascade do |t|
    t.text "cover_letter"
    t.datetime "created_at", null: false
    t.boolean "hidden", default: false, null: false
    t.bigint "job_id", null: false
    t.boolean "star", default: false, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["job_id", "user_id"], name: "index_applics_on_job_id_and_user_id", unique: true
    t.index ["job_id"], name: "index_applics_on_job_id"
    t.index ["user_id"], name: "index_applics_on_user_id"
  end

  create_table "attendees", force: :cascade do |t|
    t.string "company"
    t.datetime "created_at", null: false
    t.string "email"
    t.bigint "event_id", null: false
    t.string "firstname"
    t.string "lastname"
    t.boolean "paid"
    t.string "phone"
    t.datetime "updated_at", null: false
    t.index ["event_id"], name: "index_attendees_on_event_id"
  end

  create_table "cities", force: :cascade do |t|
    t.bigint "country_id", null: false
    t.datetime "created_at", null: false
    t.string "latitude"
    t.string "longitude"
    t.string "name"
    t.datetime "updated_at", null: false
    t.index ["country_id"], name: "index_cities_on_country_id"
  end

  create_table "countries", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.datetime "updated_at", null: false
  end

  create_table "coupons", force: :cascade do |t|
    t.bigint "administrator_id", null: false
    t.string "code"
    t.string "comment"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "value"
    t.index ["administrator_id"], name: "index_coupons_on_administrator_id"
  end

  create_table "educations", force: :cascade do |t|
    t.bigint "city_id"
    t.text "comments"
    t.bigint "country_id"
    t.datetime "created_at", null: false
    t.string "diploma"
    t.string "field_of_study"
    t.string "graduation_year"
    t.boolean "is_completed"
    t.bigint "resume_id", null: false
    t.string "school"
    t.datetime "updated_at", null: false
    t.index ["city_id"], name: "index_educations_on_city_id"
    t.index ["country_id"], name: "index_educations_on_country_id"
    t.index ["resume_id"], name: "index_educations_on_resume_id"
  end

  create_table "events", force: :cascade do |t|
    t.integer "cost"
    t.datetime "created_at", null: false
    t.text "description"
    t.datetime "ends_at"
    t.string "location"
    t.string "name"
    t.datetime "starts_at"
    t.datetime "updated_at", null: false
    t.string "youtube_url"
  end

  create_table "featured_recruiters", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.datetime "updated_at", null: false
    t.string "website_url"
  end

  create_table "jobs", force: :cascade do |t|
    t.string "apply_url"
    t.boolean "approved", default: false, null: false
    t.bigint "city_id"
    t.string "company", null: false
    t.text "company_description"
    t.string "company_url"
    t.bigint "country_id", null: false
    t.datetime "created_at", null: false
    t.text "description", null: false
    t.boolean "expired", default: false, null: false
    t.bigint "jobtype_id", null: false
    t.float "payment_amount"
    t.text "payment_comment"
    t.date "payment_date"
    t.string "payment_type"
    t.date "post_date", null: false
    t.text "qualifications", null: false
    t.bigint "sector_id", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["approved"], name: "index_jobs_on_approved"
    t.index ["city_id"], name: "index_jobs_on_city_id"
    t.index ["country_id"], name: "index_jobs_on_country_id"
    t.index ["expired"], name: "index_jobs_on_expired"
    t.index ["jobtype_id"], name: "index_jobs_on_jobtype_id"
    t.index ["post_date"], name: "index_jobs_on_post_date"
    t.index ["sector_id"], name: "index_jobs_on_sector_id"
    t.index ["user_id"], name: "index_jobs_on_user_id"
  end

  create_table "jobtypes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.datetime "updated_at", null: false
  end

  create_table "language_skills", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "language_id", null: false
    t.bigint "resume_id", null: false
    t.integer "speaking_level"
    t.datetime "updated_at", null: false
    t.integer "writing_level"
    t.index ["language_id"], name: "index_language_skills_on_language_id"
    t.index ["resume_id"], name: "index_language_skills_on_resume_id"
  end

  create_table "languages", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.datetime "updated_at", null: false
  end

  create_table "lists", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.datetime "updated_at", null: false
  end

  create_table "lists_users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "list_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["list_id"], name: "index_lists_users_on_list_id"
    t.index ["user_id"], name: "index_lists_users_on_user_id"
  end

  create_table "referrals", force: :cascade do |t|
    t.text "admin_comments"
    t.datetime "created_at", null: false
    t.string "email"
    t.string "firstname"
    t.boolean "is_verified"
    t.string "lastname"
    t.string "phone"
    t.string "relationship"
    t.bigint "resume_id", null: false
    t.datetime "updated_at", null: false
    t.index ["resume_id"], name: "index_referrals_on_resume_id"
  end

  create_table "resumes", force: :cascade do |t|
    t.string "address1"
    t.string "address2"
    t.string "birth_year", limit: 4
    t.bigint "city_id"
    t.bigint "country_id"
    t.datetime "created_at", null: false
    t.boolean "has_drivers_license", default: false, null: false
    t.boolean "is_recommended", default: false, null: false
    t.integer "nationality_id"
    t.text "objective"
    t.string "postal_code", limit: 10
    t.bigint "sector_id"
    t.string "sex", limit: 1, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.integer "years_of_experience"
    t.index ["city_id"], name: "index_resumes_on_city_id"
    t.index ["country_id"], name: "index_resumes_on_country_id"
    t.index ["is_recommended"], name: "index_resumes_on_is_recommended"
    t.index ["sector_id"], name: "index_resumes_on_sector_id"
    t.index ["user_id"], name: "index_resumes_on_user_id", unique: true
  end

  create_table "sectors", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.datetime "updated_at", null: false
  end

  create_table "share_tokens", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "expires_in", default: 7, null: false
    t.bigint "resume_id", null: false
    t.string "token", null: false
    t.datetime "updated_at", null: false
    t.index ["resume_id"], name: "index_share_tokens_on_resume_id"
    t.index ["token"], name: "index_share_tokens_on_token", unique: true
  end

  create_table "skills", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "description"
    t.bigint "resume_id", null: false
    t.datetime "updated_at", null: false
    t.index ["resume_id"], name: "index_skills_on_resume_id"
  end

  create_table "taggings", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "tag_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["tag_id"], name: "index_taggings_on_tag_id"
    t.index ["user_id"], name: "index_taggings_on_user_id"
  end

  create_table "tags", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.bigint "event_id"
    t.string "name"
    t.datetime "updated_at", null: false
    t.index ["event_id"], name: "index_tags_on_event_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "alternate_phone", limit: 15
    t.datetime "created_at", null: false
    t.datetime "current_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "firstname", null: false
    t.text "job509_comments"
    t.datetime "last_sign_in_at"
    t.string "last_sign_in_ip"
    t.string "lastname", null: false
    t.boolean "needs_password_reset", default: false
    t.string "phone", limit: 15, null: false
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.integer "role", default: 0, null: false
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["role"], name: "index_users_on_role"
  end

  create_table "work_experiences", force: :cascade do |t|
    t.bigint "city_id"
    t.string "company"
    t.bigint "country_id"
    t.datetime "created_at", null: false
    t.text "description"
    t.string "ending_month"
    t.string "ending_year"
    t.boolean "is_current"
    t.bigint "jobtype_id"
    t.string "monthly_salary"
    t.bigint "resume_id", null: false
    t.bigint "sector_id"
    t.string "starting_month"
    t.string "starting_year"
    t.string "title"
    t.datetime "updated_at", null: false
    t.index ["city_id"], name: "index_work_experiences_on_city_id"
    t.index ["country_id"], name: "index_work_experiences_on_country_id"
    t.index ["jobtype_id"], name: "index_work_experiences_on_jobtype_id"
    t.index ["resume_id"], name: "index_work_experiences_on_resume_id"
    t.index ["sector_id"], name: "index_work_experiences_on_sector_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "applics", "jobs"
  add_foreign_key "applics", "users"
  add_foreign_key "attendees", "events"
  add_foreign_key "cities", "countries"
  add_foreign_key "coupons", "administrators"
  add_foreign_key "educations", "cities"
  add_foreign_key "educations", "countries"
  add_foreign_key "educations", "resumes"
  add_foreign_key "jobs", "cities"
  add_foreign_key "jobs", "countries"
  add_foreign_key "jobs", "jobtypes"
  add_foreign_key "jobs", "sectors"
  add_foreign_key "jobs", "users"
  add_foreign_key "language_skills", "languages"
  add_foreign_key "language_skills", "resumes"
  add_foreign_key "lists_users", "lists"
  add_foreign_key "lists_users", "users"
  add_foreign_key "referrals", "resumes"
  add_foreign_key "resumes", "cities"
  add_foreign_key "resumes", "countries"
  add_foreign_key "resumes", "countries", column: "nationality_id"
  add_foreign_key "resumes", "sectors"
  add_foreign_key "resumes", "users"
  add_foreign_key "share_tokens", "resumes"
  add_foreign_key "skills", "resumes"
  add_foreign_key "taggings", "tags"
  add_foreign_key "taggings", "users"
  add_foreign_key "tags", "events"
  add_foreign_key "work_experiences", "cities"
  add_foreign_key "work_experiences", "countries"
  add_foreign_key "work_experiences", "jobtypes"
  add_foreign_key "work_experiences", "resumes"
  add_foreign_key "work_experiences", "sectors"
end
