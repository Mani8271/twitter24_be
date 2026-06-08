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

ActiveRecord::Schema[7.1].define(version: 2026_06_02_131000) do
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
    t.string "address_line1"
    t.string "address_line2"
    t.string "city"
    t.string "state"
    t.string "pincode"
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

  create_table "business_upgrade_requests", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "request_status", default: "pending", null: false
    t.datetime "requested_at", null: false
    t.string "approved_by"
    t.datetime "approved_at"
    t.text "rejection_reason"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "rejected_by"
    t.datetime "rejected_at"
    t.index ["request_status"], name: "index_business_upgrade_requests_on_request_status"
    t.index ["user_id", "request_status"], name: "index_bur_on_user_and_status"
    t.index ["user_id"], name: "index_business_upgrade_requests_on_user_id"
  end

  create_table "businesses", force: :cascade do |t|
    t.integer "user_id"
    t.string "name"
    t.string "category"
    t.integer "year_established"
    t.string "website"
    t.text "about"
    t.jsonb "products_services"
    t.string "status", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.float "average_rating"
    t.integer "reviews_count"
    t.boolean "is_online", default: false, null: false
    t.text "keywords", default: [], array: true
    t.text "video_links", default: [], array: true
    t.text "rejection_reason"
    t.index ["user_id"], name: "index_businesses_on_user_id", unique: true
    t.check_constraint "status::text = ANY (ARRAY['draft'::character varying, 'submitted'::character varying, 'approved'::character varying, 'rejected'::character varying]::text[])", name: "businesses_status_check"
  end

  create_table "comments", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "commentable_type", null: false
    t.bigint "commentable_id", null: false
    t.text "body"
    t.integer "parent_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["commentable_type", "commentable_id"], name: "index_comments_on_commentable"
    t.index ["parent_id"], name: "index_comments_on_parent_id"
    t.index ["user_id"], name: "index_comments_on_user_id"
  end

  create_table "contents", force: :cascade do |t|
    t.string "title"
    t.string "subtitle"
    t.text "content"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "follows", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "followable_type", null: false
    t.bigint "followable_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["followable_type", "followable_id"], name: "index_follows_on_followable"
    t.index ["user_id", "followable_type", "followable_id"], name: "index_follows_on_user_followable_unique", unique: true
    t.index ["user_id"], name: "index_follows_on_user_id"
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
    t.string "feed_type", default: "global", null: false
    t.float "latitude"
    t.float "longitude"
    t.string "address"
    t.integer "user_id"
    t.integer "reach_distance"
    t.index ["feed_type"], name: "index_global_feeds_on_feed_type"
    t.index ["latitude", "longitude"], name: "index_global_feeds_on_latitude_and_longitude"
    t.index ["user_id"], name: "index_global_feeds_on_user_id"
  end

  create_table "jobs", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "location_name"
    t.decimal "latitude", precision: 10, scale: 6
    t.decimal "longitude", precision: 10, scale: 6
    t.integer "reach_distance"
    t.string "job_title", null: false
    t.string "salary"
    t.string "experience"
    t.string "job_type"
    t.string "working_hours"
    t.text "description"
    t.text "skills_required"
    t.jsonb "links", default: []
    t.string "tags"
    t.integer "disappearing_days"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "post_type", default: "local", null: false
    t.index ["created_at"], name: "index_jobs_on_created_at"
    t.index ["job_type"], name: "index_jobs_on_job_type"
    t.index ["links"], name: "index_jobs_on_links", using: :gin
    t.index ["post_type"], name: "index_jobs_on_post_type"
    t.index ["user_id"], name: "index_jobs_on_user_id"
  end

  create_table "likes", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "likeable_type", null: false
    t.bigint "likeable_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["likeable_type", "likeable_id"], name: "index_likes_on_likeable"
    t.index ["user_id", "likeable_type", "likeable_id"], name: "index_likes_on_user_id_and_likeable_type_and_likeable_id", unique: true
    t.index ["user_id"], name: "index_likes_on_user_id"
  end

  create_table "live_locations", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.float "latitude"
    t.float "longitude"
    t.string "address"
    t.string "city"
    t.string "state"
    t.string "country"
    t.boolean "live_location_default", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "live_location_default"], name: "index_live_locations_on_user_id_and_live_location_default"
    t.index ["user_id"], name: "index_live_locations_on_user_id"
  end

  create_table "offers", force: :cascade do |t|
    t.string "title", null: false
    t.text "description", null: false
    t.string "offer_type", default: "global", null: false
    t.float "latitude"
    t.float "longitude"
    t.string "address"
    t.integer "reach_distance"
    t.datetime "valid_till"
    t.string "tags"
    t.integer "disappearing_days"
    t.jsonb "links", default: []
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "valid_from"
    t.index ["latitude", "longitude"], name: "index_offers_on_latitude_and_longitude"
    t.index ["offer_type"], name: "index_offers_on_offer_type"
    t.index ["user_id"], name: "index_offers_on_user_id"
    t.index ["valid_till"], name: "index_offers_on_valid_till"
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

  create_table "payments", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "subscription_plan_id", null: false
    t.string "merchant_transaction_id", null: false
    t.string "phonepe_transaction_id"
    t.integer "amount_in_paise", null: false
    t.string "gst_in"
    t.string "status", default: "pending", null: false
    t.jsonb "gateway_response", default: {}
    t.datetime "paid_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["merchant_transaction_id"], name: "index_payments_on_merchant_transaction_id", unique: true
    t.index ["status"], name: "index_payments_on_status"
    t.index ["subscription_plan_id"], name: "index_payments_on_subscription_plan_id"
    t.index ["user_id"], name: "index_payments_on_user_id"
  end

  create_table "reach_distance_settings", force: :cascade do |t|
    t.text "ranges"
    t.boolean "is_active"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "reviews", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "business_id", null: false
    t.integer "rating"
    t.text "comment"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_id"], name: "index_reviews_on_business_id"
    t.index ["user_id"], name: "index_reviews_on_user_id"
  end

  create_table "subscription_plans", force: :cascade do |t|
    t.string "plan_type", null: false
    t.jsonb "features", default: [], null: false
    t.string "amounts", null: false
    t.integer "position", default: 0, null: false
    t.boolean "is_active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "limits", default: {}, null: false
    t.jsonb "ranges", default: {}, null: false
    t.jsonb "disappear_days", default: {}, null: false
    t.index ["plan_type"], name: "index_subscription_plans_on_plan_type", unique: true
    t.index ["position"], name: "index_subscription_plans_on_position"
  end

  create_table "users", force: :cascade do |t|
    t.string "name", null: false
    t.string "email"
    t.boolean "email_verified", default: false
    t.boolean "phone_verified", default: false
    t.string "phone_number", null: false
    t.string "password_digest"
    t.string "current_location_size_id"
    t.string "country_id"
    t.string "region_id"
    t.string "zone_location_id"
    t.string "currency_pref"
    t.text "followin_business", default: "--- []\n"
    t.boolean "is_online", default: false
    t.string "status", default: "", null: false
    t.string "account_type", default: "user"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.boolean "is_subscription_completed", default: false, null: false
    t.bigint "subscription_plan_id"
    t.integer "otp_resend_count", default: 0, null: false
    t.datetime "otp_resend_window_start"
    t.jsonb "subscribed_features", default: []
    t.jsonb "subscribed_limits", default: {}
    t.jsonb "subscribed_ranges", default: {}
    t.datetime "subscribed_at"
    t.jsonb "subscribed_disappear_days", default: {}
    t.boolean "is_active", default: true, null: false
    t.datetime "subscription_expires_at"
    t.jsonb "subscription_usage", default: {}, null: false
    t.integer "token_version", default: 0, null: false
    t.boolean "is_new_business_user", default: false
    t.index ["deleted_at"], name: "index_users_on_deleted_at"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["phone_number"], name: "index_users_on_phone_number", unique: true
    t.index ["subscription_plan_id"], name: "index_users_on_subscription_plan_id"
    t.index ["subscription_usage"], name: "index_users_on_subscription_usage", using: :gin
  end

  create_table "versions", force: :cascade do |t|
    t.string "item_type", null: false
    t.bigint "item_id", null: false
    t.string "event", null: false
    t.string "whodunnit"
    t.text "object"
    t.text "object_changes"
    t.jsonb "meta", default: {}
    t.datetime "created_at"
    t.index ["created_at"], name: "index_versions_on_created_at"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
    t.index ["whodunnit"], name: "index_versions_on_whodunnit"
  end

  create_table "views", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "viewable_type", null: false
    t.bigint "viewable_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "viewable_type", "viewable_id"], name: "index_views_on_user_id_and_viewable_type_and_viewable_id", unique: true
    t.index ["user_id"], name: "index_views_on_user_id"
    t.index ["viewable_type", "viewable_id"], name: "index_views_on_viewable"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "business_contacts", "businesses"
  add_foreign_key "business_documents", "businesses"
  add_foreign_key "business_hours", "businesses"
  add_foreign_key "business_locations", "businesses"
  add_foreign_key "business_upgrade_requests", "users"
  add_foreign_key "businesses", "users"
  add_foreign_key "comments", "users"
  add_foreign_key "follows", "users"
  add_foreign_key "global_feeds", "users", on_delete: :cascade
  add_foreign_key "jobs", "users"
  add_foreign_key "likes", "users"
  add_foreign_key "live_locations", "users"
  add_foreign_key "offers", "users"
  add_foreign_key "onboarding_progresses", "businesses"
  add_foreign_key "onboarding_progresses", "users"
  add_foreign_key "payments", "subscription_plans"
  add_foreign_key "payments", "users"
  add_foreign_key "reviews", "businesses"
  add_foreign_key "reviews", "users"
  add_foreign_key "users", "subscription_plans"
  add_foreign_key "views", "users"
end
