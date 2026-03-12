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

ActiveRecord::Schema[8.1].define(version: 2026_03_12_082000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "accesses", force: :cascade do |t|
    t.integer "book_id", null: false
    t.datetime "created_at", null: false
    t.string "level", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["book_id"], name: "index_accesses_on_book_id"
    t.index ["user_id", "book_id"], name: "index_accesses_on_user_id_and_book_id", unique: true
    t.index ["user_id"], name: "index_accesses_on_user_id"
  end

  create_table "accounts", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "custom_styles"
    t.string "join_code", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
  end

  create_table "action_text_markdowns", force: :cascade do |t|
    t.text "content", default: "", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.integer "record_id", null: false
    t.string "record_type", null: false
    t.datetime "updated_at", null: false
    t.index ["record_type", "record_id"], name: "index_action_text_markdowns_on_record"
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.string "slug"
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
    t.index ["slug"], name: "index_active_storage_attachments_on_slug", unique: true
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

  create_table "api_key_events", force: :cascade do |t|
    t.string "action", null: false
    t.bigint "api_key_id", null: false
    t.datetime "created_at", null: false
    t.jsonb "metadata", default: {}, null: false
    t.bigint "subject_id", null: false
    t.string "subject_type", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["api_key_id", "created_at"], name: "index_api_key_events_on_api_key_id_and_created_at"
    t.index ["api_key_id"], name: "index_api_key_events_on_api_key_id"
    t.index ["subject_type", "subject_id"], name: "index_api_key_events_on_subject_type_and_subject_id"
    t.index ["user_id"], name: "index_api_key_events_on_user_id"
  end

  create_table "api_keys", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "key_digest", null: false
    t.datetime "last_used_at"
    t.string "name", null: false
    t.datetime "revoked_at"
    t.string "scopes", default: [], null: false, array: true
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["key_digest"], name: "index_api_keys_on_key_digest", unique: true
    t.index ["revoked_at"], name: "index_api_keys_on_revoked_at"
    t.index ["user_id"], name: "index_api_keys_on_user_id"
  end

  create_table "book_ingestions", force: :cascade do |t|
    t.bigint "api_key_id", null: false
    t.datetime "applied_at"
    t.bigint "book_id"
    t.datetime "created_at", null: false
    t.text "error_message"
    t.integer "expected_revision"
    t.string "parser_version", null: false
    t.jsonb "plan", default: {}, null: false
    t.jsonb "result", default: {}, null: false
    t.string "source_sha256", null: false
    t.string "status", default: "uploaded", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["api_key_id"], name: "index_book_ingestions_on_api_key_id"
    t.index ["book_id"], name: "index_book_ingestions_on_book_id"
    t.index ["status"], name: "index_book_ingestions_on_status"
    t.index ["user_id"], name: "index_book_ingestions_on_user_id"
  end

  create_table "book_tags", force: :cascade do |t|
    t.bigint "book_id", null: false
    t.datetime "created_at", null: false
    t.bigint "tag_id", null: false
    t.datetime "updated_at", null: false
    t.index ["book_id", "tag_id"], name: "index_book_tags_on_book_id_and_tag_id", unique: true
    t.index ["book_id"], name: "index_book_tags_on_book_id"
    t.index ["tag_id"], name: "index_book_tags_on_tag_id"
  end

  create_table "book_units", force: :cascade do |t|
    t.bigint "book_id", null: false
    t.string "content_sha256", null: false
    t.datetime "created_at", null: false
    t.string "external_id", null: false
    t.bigint "leaf_id", null: false
    t.integer "position", null: false
    t.datetime "updated_at", null: false
    t.index ["book_id", "external_id"], name: "index_book_units_on_book_id_and_external_id", unique: true
    t.index ["book_id"], name: "index_book_units_on_book_id"
    t.index ["leaf_id"], name: "index_book_units_on_leaf_id"
  end

  create_table "book_views", force: :cascade do |t|
    t.bigint "book_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.date "viewed_on", null: false
    t.string "visitor_id"
    t.index ["book_id", "viewed_on", "user_id"], name: "index_book_views_on_book_date_user", unique: true, where: "(user_id IS NOT NULL)"
    t.index ["book_id", "viewed_on", "visitor_id"], name: "index_book_views_on_book_date_visitor", unique: true, where: "(visitor_id IS NOT NULL)"
    t.index ["book_id"], name: "index_book_views_on_book_id"
    t.index ["user_id"], name: "index_book_views_on_user_id"
  end

  create_table "books", force: :cascade do |t|
    t.string "author"
    t.bigint "category_id", null: false
    t.datetime "created_at", null: false
    t.boolean "everyone_access", default: true, null: false
    t.integer "ingestion_revision", default: 0, null: false
    t.integer "price_cents"
    t.string "pricing_type", default: "free", null: false
    t.boolean "published", default: false, null: false
    t.string "slug", null: false
    t.string "stripe_product_id"
    t.string "subtitle"
    t.string "theme", default: "blue", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["category_id"], name: "index_books_on_category_id"
    t.index ["pricing_type"], name: "index_books_on_pricing_type"
    t.index ["published"], name: "index_books_on_published"
    t.index ["stripe_product_id"], name: "index_books_on_stripe_product_id"
  end

  create_table "categories", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_categories_on_name", unique: true
    t.index ["slug"], name: "index_categories_on_slug", unique: true
  end

  create_table "edits", force: :cascade do |t|
    t.string "action", null: false
    t.datetime "created_at", null: false
    t.integer "leaf_id", null: false
    t.integer "leafable_id", null: false
    t.string "leafable_type", null: false
    t.datetime "updated_at", null: false
    t.index ["leaf_id"], name: "index_edits_on_leaf_id"
    t.index ["leafable_type", "leafable_id"], name: "index_edits_on_leafable"
  end

  create_table "idempotency_keys", force: :cascade do |t|
    t.bigint "api_key_id", null: false
    t.datetime "created_at", null: false
    t.string "key", null: false
    t.string "request_fingerprint", null: false
    t.text "response_body"
    t.integer "response_status"
    t.datetime "updated_at", null: false
    t.index ["api_key_id", "key"], name: "index_idempotency_keys_on_api_key_id_and_key", unique: true
    t.index ["api_key_id"], name: "index_idempotency_keys_on_api_key_id"
  end

  create_table "leaf_search_index", primary_key: "rowid", force: :cascade do |t|
    t.text "content"
    t.text "title"
    t.index ["rowid"], name: "index_leaf_search_index_on_rowid", unique: true
  end

  create_table "leaves", force: :cascade do |t|
    t.integer "book_id", null: false
    t.datetime "created_at", null: false
    t.integer "leafable_id", null: false
    t.string "leafable_type", null: false
    t.float "position_score", null: false
    t.string "status", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["book_id"], name: "index_leaves_on_book_id"
    t.index ["leafable_type", "leafable_id"], name: "index_leafs_on_leafable"
  end

  create_table "pages", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "pay_charges", force: :cascade do |t|
    t.integer "amount", null: false
    t.integer "amount_refunded"
    t.integer "application_fee_amount"
    t.datetime "created_at", null: false
    t.string "currency"
    t.bigint "customer_id", null: false
    t.jsonb "data"
    t.jsonb "metadata"
    t.jsonb "object"
    t.string "processor_id", null: false
    t.string "stripe_account"
    t.bigint "subscription_id"
    t.string "type"
    t.datetime "updated_at", null: false
    t.index ["customer_id", "processor_id"], name: "index_pay_charges_on_customer_id_and_processor_id", unique: true
    t.index ["subscription_id"], name: "index_pay_charges_on_subscription_id"
  end

  create_table "pay_customers", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.jsonb "data"
    t.boolean "default"
    t.datetime "deleted_at", precision: nil
    t.jsonb "object"
    t.bigint "owner_id"
    t.string "owner_type"
    t.string "processor", null: false
    t.string "processor_id"
    t.string "stripe_account"
    t.string "type"
    t.datetime "updated_at", null: false
    t.index ["owner_type", "owner_id", "deleted_at"], name: "pay_customer_owner_index", unique: true
    t.index ["processor", "processor_id"], name: "index_pay_customers_on_processor_and_processor_id", unique: true
  end

  create_table "pay_merchants", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.jsonb "data"
    t.boolean "default"
    t.bigint "owner_id"
    t.string "owner_type"
    t.string "processor", null: false
    t.string "processor_id"
    t.string "type"
    t.datetime "updated_at", null: false
    t.index ["owner_type", "owner_id", "processor"], name: "index_pay_merchants_on_owner_type_and_owner_id_and_processor"
  end

  create_table "pay_payment_methods", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "customer_id", null: false
    t.jsonb "data"
    t.boolean "default"
    t.string "payment_method_type"
    t.string "processor_id", null: false
    t.string "stripe_account"
    t.string "type"
    t.datetime "updated_at", null: false
    t.index ["customer_id", "processor_id"], name: "index_pay_payment_methods_on_customer_id_and_processor_id", unique: true
  end

  create_table "pay_subscriptions", force: :cascade do |t|
    t.decimal "application_fee_percent", precision: 8, scale: 2
    t.datetime "created_at", null: false
    t.datetime "current_period_end", precision: nil
    t.datetime "current_period_start", precision: nil
    t.bigint "customer_id", null: false
    t.jsonb "data"
    t.datetime "ends_at", precision: nil
    t.jsonb "metadata"
    t.boolean "metered"
    t.string "name", null: false
    t.jsonb "object"
    t.string "pause_behavior"
    t.datetime "pause_resumes_at", precision: nil
    t.datetime "pause_starts_at", precision: nil
    t.string "payment_method_id"
    t.string "processor_id", null: false
    t.string "processor_plan", null: false
    t.integer "quantity", default: 1, null: false
    t.string "status", null: false
    t.string "stripe_account"
    t.datetime "trial_ends_at", precision: nil
    t.string "type"
    t.datetime "updated_at", null: false
    t.index ["customer_id", "processor_id"], name: "index_pay_subscriptions_on_customer_id_and_processor_id", unique: true
    t.index ["metered"], name: "index_pay_subscriptions_on_metered"
    t.index ["pause_starts_at"], name: "index_pay_subscriptions_on_pause_starts_at"
  end

  create_table "pay_webhooks", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.jsonb "event"
    t.string "event_type"
    t.string "processor"
    t.datetime "updated_at", null: false
  end

  create_table "pictures", force: :cascade do |t|
    t.string "caption"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "sections", force: :cascade do |t|
    t.text "body"
    t.datetime "created_at", null: false
    t.string "theme"
    t.datetime "updated_at", null: false
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "last_active_at", null: false
    t.string "token", null: false
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.integer "user_id", null: false
    t.index ["token"], name: "index_sessions_on_token", unique: true
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "tags", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_tags_on_name", unique: true
    t.index ["slug"], name: "index_tags_on_slug", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.string "name", null: false
    t.string "password_digest", null: false
    t.integer "role", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
    t.index ["name"], name: "index_users_on_name", unique: true
  end

  add_foreign_key "accesses", "books"
  add_foreign_key "accesses", "users"
  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "api_key_events", "api_keys"
  add_foreign_key "api_key_events", "users"
  add_foreign_key "api_keys", "users"
  add_foreign_key "book_ingestions", "api_keys"
  add_foreign_key "book_ingestions", "books"
  add_foreign_key "book_ingestions", "users"
  add_foreign_key "book_tags", "books"
  add_foreign_key "book_tags", "tags"
  add_foreign_key "book_units", "books"
  add_foreign_key "book_units", "leaves"
  add_foreign_key "book_views", "books"
  add_foreign_key "book_views", "users"
  add_foreign_key "books", "categories"
  add_foreign_key "edits", "leaves"
  add_foreign_key "idempotency_keys", "api_keys"
  add_foreign_key "leaves", "books"
  add_foreign_key "pay_charges", "pay_customers", column: "customer_id"
  add_foreign_key "pay_charges", "pay_subscriptions", column: "subscription_id"
  add_foreign_key "pay_payment_methods", "pay_customers", column: "customer_id"
  add_foreign_key "pay_subscriptions", "pay_customers", column: "customer_id"
  add_foreign_key "sessions", "users"
end
