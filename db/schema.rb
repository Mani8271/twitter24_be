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

ActiveRecord::Schema[7.1].define(version: 2026_01_02_161559) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "active_admin_comments", force: :cascade do |t|
    t.string "namespace"
    t.text "body"
    t.string "resource_type"
    t.bigint "resource_id"
    t.string "author_type"
    t.bigint "author_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["author_type", "author_id"], name: "index_active_admin_comments_on_author"
    t.index ["namespace"], name: "index_active_admin_comments_on_namespace"
    t.index ["resource_type", "resource_id"], name: "index_active_admin_comments_on_resource"
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "admin_users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_admin_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_admin_users_on_reset_password_token", unique: true
  end

  create_table "business_contacts", force: :cascade do |t|
    t.integer "business_id"
    t.string "contact_person_name"
    t.string "contact_phone"
    t.boolean "contact_phone_verified"
    t.string "contact_email"
    t.string "owner_name"
    t.string "owner_phone"
    t.boolean "owner_phone_verified"
    t.string "owner_email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_id"], name: "index_business_contacts_on_business_id", unique: true
  end

  create_table "business_documents", force: :cascade do |t|
    t.integer "business_id"
    t.boolean "has_gstin"
    t.string "gstin"
    t.boolean "has_pan"
    t.string "pan"
    t.boolean "has_fssai"
    t.string "fssai"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_id"], name: "index_business_documents_on_business_id", unique: true
  end

  create_table "business_hours", force: :cascade do |t|
    t.integer "business_id"
    t.integer "day_of_week"
    t.boolean "is_open"
    t.time "opens_at"
    t.time "closes_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_id", "day_of_week"], name: "index_business_hours_on_business_id_and_day_of_week", unique: true
  end

  create_table "business_locations", force: :cascade do |t|
    t.integer "business_id"
    t.string "map_address"
    t.decimal "latitude", precision: 10, scale: 6
    t.decimal "longitude", precision: 10, scale: 6
    t.string "place_id"
    t.string "address_line1"
    t.string "address_line2"
    t.string "city"
    t.string "state"
    t.string "pin_code"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_id"], name: "index_business_locations_on_business_id", unique: true
  end

  create_table "businesses", force: :cascade do |t|
    t.integer "user_id"
    t.string "name"
    t.string "category"
    t.integer "year_established"
    t.string "website"
    t.text "about"
    t.jsonb "products_services"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_businesses_on_user_id", unique: true
  end

  create_table "contents", force: :cascade do |t|
    t.string "title"
    t.string "subtitle"
    t.text "content"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "global_feeds", force: :cascade do |t|
    t.string "title"
    t.text "description"
    t.string "category"
    t.integer "disappear_after"
    t.json "tags"
    t.json "links"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "onboarding_progresses", force: :cascade do |t|
    t.integer "user_id"
    t.integer "business_id"
    t.integer "current_step"
    t.jsonb "steps_completed"
    t.boolean "completed"
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_id"], name: "index_onboarding_progresses_on_business_id"
    t.index ["user_id"], name: "index_onboarding_progresses_on_user_id", unique: true
  end

  create_table "otp_codes", force: :cascade do |t|
    t.string "user_id", null: false
    t.string "phone_number", null: false
    t.string "otp_number", null: false
    t.datetime "otp_expiry", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["otp_number"], name: "index_otp_codes_on_otp_number", unique: true
    t.index ["phone_number"], name: "index_otp_codes_on_phone_number"
    t.index ["user_id"], name: "index_otp_codes_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "name", null: false
    t.string "email"
    t.boolean "email_verified", default: false
    t.boolean "phone_verified", default: false
    t.string "phone_number", null: false
    t.string "password_digest"
    t.string "profile_picture"
    t.string "current_location_size_id"
    t.string "country_id"
    t.string "region_id"
    t.string "zone_location_id"
    t.string "currency_pref"
    t.text "followin_business", default: "--- []\n"
    t.boolean "is_online", default: false
    t.string "status"
    t.string "account_type", default: "user"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["phone_number"], name: "index_users_on_phone_number", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "business_contacts", "businesses"
  add_foreign_key "business_documents", "businesses"
  add_foreign_key "business_hours", "businesses"
  add_foreign_key "business_locations", "businesses"
  add_foreign_key "businesses", "users"
  add_foreign_key "onboarding_progresses", "businesses"
  add_foreign_key "onboarding_progresses", "users"
end
