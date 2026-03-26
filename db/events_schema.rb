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

ActiveRecord::Schema[8.1].define(version: 2026_03_26_130000) do
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

  create_table "agent_claims", force: :cascade do |t|
    t.bigint "agent_id"
    t.datetime "claimed_at"
    t.bigint "claimed_by_user_id"
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.string "token_digest", null: false
    t.datetime "updated_at", null: false
    t.index ["agent_id"], name: "index_agent_claims_on_agent_id"
    t.index ["claimed_by_user_id"], name: "index_agent_claims_on_claimed_by_user_id"
    t.index ["token_digest"], name: "index_agent_claims_on_token_digest", unique: true
  end

  create_table "agents", force: :cascade do |t|
    t.datetime "claimed_at"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "owner_user_id"
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.string "username", null: false
    t.index ["owner_user_id"], name: "index_agents_on_owner_user_id"
    t.index ["slug"], name: "index_agents_on_slug", unique: true
    t.index ["username"], name: "index_agents_on_username", unique: true
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
    t.bigint "agent_id"
    t.datetime "created_at", null: false
    t.string "key_digest", null: false
    t.datetime "last_used_at"
    t.string "name", null: false
    t.datetime "revoked_at"
    t.string "scopes", default: [], null: false, array: true
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["agent_id"], name: "index_api_keys_on_agent_id"
    t.index ["key_digest"], name: "index_api_keys_on_key_digest", unique: true
    t.index ["revoked_at"], name: "index_api_keys_on_revoked_at"
    t.index ["user_id"], name: "index_api_keys_on_user_id"
  end

  create_table "book_revisions", force: :cascade do |t|
    t.bigint "book_id", null: false
    t.datetime "created_at", null: false
    t.jsonb "diff_summary", default: {}, null: false
    t.jsonb "metadata", default: {}, null: false
    t.integer "number", null: false
    t.string "source_sha256", null: false
    t.jsonb "units", default: [], null: false
    t.datetime "updated_at", null: false
    t.bigint "upload_id", null: false
    t.index ["book_id", "number"], name: "index_book_revisions_on_book_id_and_number", unique: true
    t.index ["book_id"], name: "index_book_revisions_on_book_id"
    t.index ["upload_id"], name: "index_book_revisions_on_upload_id"
  end

  create_table "book_sales", force: :cascade do |t|
    t.bigint "book_id", null: false
    t.bigint "buyer_user_id", null: false
    t.datetime "created_at", null: false
    t.string "currency", null: false
    t.integer "gross_cents", null: false
    t.integer "net_cents", null: false
    t.bigint "pay_charge_id", null: false
    t.integer "platform_amount_cents", null: false
    t.integer "seller_amount_cents", null: false
    t.bigint "seller_user_id", null: false
    t.integer "stripe_fee_cents", null: false
    t.string "stripe_transfer_id"
    t.datetime "transferred_at"
    t.datetime "updated_at", null: false
    t.index ["book_id"], name: "index_book_sales_on_book_id"
    t.index ["buyer_user_id"], name: "index_book_sales_on_buyer_user_id"
    t.index ["pay_charge_id"], name: "index_book_sales_on_pay_charge_id", unique: true
    t.index ["seller_user_id"], name: "index_book_sales_on_seller_user_id"
    t.index ["stripe_transfer_id"], name: "index_book_sales_on_stripe_transfer_id", unique: true
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
    t.string "book_uid"
    t.bigint "category_id", null: false
    t.datetime "created_at", null: false
    t.bigint "current_draft_revision_id"
    t.boolean "everyone_access", default: false, null: false
    t.integer "import_revision", default: 0, null: false
    t.integer "price_cents"
    t.string "price_currency", default: "USD", null: false
    t.string "pricing_type", default: "free", null: false
    t.boolean "published", default: false, null: false
    t.bigint "published_revision_id"
    t.bigint "seller_user_id"
    t.string "slug", null: false
    t.string "stripe_product_id"
    t.string "subtitle"
    t.string "theme", default: "blue", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["book_uid"], name: "index_books_on_book_uid", unique: true
    t.index ["category_id"], name: "index_books_on_category_id"
    t.index ["current_draft_revision_id"], name: "index_books_on_current_draft_revision_id"
    t.index ["price_currency"], name: "index_books_on_price_currency"
    t.index ["pricing_type"], name: "index_books_on_pricing_type"
    t.index ["published"], name: "index_books_on_published"
    t.index ["published_revision_id"], name: "index_books_on_published_revision_id"
    t.index ["seller_user_id"], name: "index_books_on_seller_user_id"
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

  create_table "identities", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email"
    t.string "provider", null: false
    t.string "uid", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["provider", "uid"], name: "index_identities_on_provider_and_uid", unique: true
    t.index ["user_id"], name: "index_identities_on_user_id"
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

  create_table "solid_events_causal_edges", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "edge_type", default: "caused_by", null: false
    t.bigint "from_event_id"
    t.bigint "from_trace_id"
    t.datetime "occurred_at", null: false
    t.json "payload", default: {}
    t.bigint "to_event_id"
    t.bigint "to_trace_id", null: false
    t.datetime "updated_at", null: false
    t.index ["from_event_id", "to_trace_id"], name: "index_solid_events_causal_edges_uniqueness", unique: true
    t.index ["from_event_id"], name: "index_solid_events_causal_edges_on_from_event_id"
    t.index ["from_trace_id"], name: "index_solid_events_causal_edges_on_from_trace_id"
    t.index ["occurred_at"], name: "index_solid_events_causal_edges_on_occurred_at"
    t.index ["to_trace_id"], name: "index_solid_events_causal_edges_on_to_trace_id"
  end

  create_table "solid_events_error_links", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "solid_error_id", null: false
    t.bigint "trace_id", null: false
    t.datetime "updated_at", null: false
    t.index ["trace_id", "solid_error_id"], name: "index_solid_events_error_links_on_trace_id_and_solid_error_id", unique: true
    t.index ["trace_id"], name: "index_solid_events_error_links_on_trace_id"
  end

  create_table "solid_events_events", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.float "duration_ms"
    t.string "event_type", null: false
    t.string "name", null: false
    t.datetime "occurred_at", null: false
    t.json "payload", default: {}
    t.bigint "trace_id", null: false
    t.datetime "updated_at", null: false
    t.index ["event_type"], name: "index_solid_events_events_on_event_type"
    t.index ["occurred_at"], name: "index_solid_events_events_on_occurred_at"
    t.index ["trace_id"], name: "index_solid_events_events_on_trace_id"
  end

  create_table "solid_events_incident_events", force: :cascade do |t|
    t.string "action", null: false
    t.string "actor"
    t.datetime "created_at", null: false
    t.bigint "incident_id", null: false
    t.datetime "occurred_at", null: false
    t.json "payload", default: {}
    t.datetime "updated_at", null: false
    t.index ["action"], name: "index_solid_events_incident_events_on_action"
    t.index ["incident_id", "action", "occurred_at"], name: "index_solid_events_incident_events_on_incident_action_time"
    t.index ["incident_id", "occurred_at"], name: "index_solid_events_incident_events_on_incident_and_time"
    t.index ["incident_id"], name: "index_solid_events_incident_events_on_incident_id"
    t.index ["occurred_at"], name: "index_solid_events_incident_events_on_occurred_at"
  end

  create_table "solid_events_incidents", force: :cascade do |t|
    t.datetime "acknowledged_at"
    t.datetime "assigned_at"
    t.string "assigned_by"
    t.text "assignment_note"
    t.datetime "created_at", null: false
    t.datetime "detected_at", null: false
    t.string "fingerprint"
    t.string "kind", null: false
    t.datetime "last_seen_at", null: false
    t.datetime "muted_until"
    t.string "name"
    t.string "owner"
    t.json "payload", default: {}
    t.text "resolution_note"
    t.datetime "resolved_at"
    t.string "resolved_by"
    t.string "severity", default: "warning", null: false
    t.string "source"
    t.string "status", default: "active", null: false
    t.string "team"
    t.datetime "updated_at", null: false
    t.index ["assigned_at"], name: "index_solid_events_incidents_on_assigned_at"
    t.index ["assigned_by"], name: "index_solid_events_incidents_on_assigned_by"
    t.index ["detected_at"], name: "index_solid_events_incidents_on_detected_at"
    t.index ["fingerprint"], name: "index_solid_events_incidents_on_fingerprint"
    t.index ["kind"], name: "index_solid_events_incidents_on_kind"
    t.index ["name"], name: "index_solid_events_incidents_on_name"
    t.index ["owner"], name: "index_solid_events_incidents_on_owner"
    t.index ["severity"], name: "index_solid_events_incidents_on_severity"
    t.index ["source"], name: "index_solid_events_incidents_on_source"
    t.index ["status"], name: "index_solid_events_incidents_on_status"
    t.index ["team"], name: "index_solid_events_incidents_on_team"
  end

  create_table "solid_events_journeys", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "entity_id"
    t.string "entity_type"
    t.integer "error_count", default: 0, null: false
    t.datetime "finished_at", null: false
    t.string "journey_key", null: false
    t.bigint "last_trace_id"
    t.json "payload", default: {}
    t.string "request_id"
    t.datetime "started_at", null: false
    t.integer "trace_count", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["entity_type", "entity_id"], name: "index_solid_events_journeys_on_entity_type_and_entity_id"
    t.index ["finished_at"], name: "index_solid_events_journeys_on_finished_at"
    t.index ["journey_key"], name: "index_solid_events_journeys_on_journey_key", unique: true
    t.index ["request_id"], name: "index_solid_events_journeys_on_request_id"
  end

  create_table "solid_events_record_links", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.bigint "trace_id", null: false
    t.datetime "updated_at", null: false
    t.index ["record_type", "record_id"], name: "index_solid_events_record_links_on_record_type_and_record_id"
    t.index ["trace_id", "record_type", "record_id"], name: "index_solid_events_record_links_uniqueness", unique: true
    t.index ["trace_id"], name: "index_solid_events_record_links_on_trace_id"
  end

  create_table "solid_events_saved_views", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "created_by"
    t.json "filters", default: {}
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_solid_events_saved_views_on_created_at"
    t.index ["name"], name: "index_solid_events_saved_views_on_name"
  end

  create_table "solid_events_summaries", force: :cascade do |t|
    t.bigint "account_id"
    t.bigint "caused_by_event_id"
    t.bigint "caused_by_trace_id"
    t.datetime "created_at", null: false
    t.string "deployment_id"
    t.float "duration_ms"
    t.bigint "entity_id"
    t.string "entity_type"
    t.string "environment_name"
    t.integer "error_count", default: 0, null: false
    t.string "error_fingerprint"
    t.integer "event_count", default: 0, null: false
    t.datetime "finished_at"
    t.integer "http_status"
    t.string "job_class"
    t.string "name", null: false
    t.string "outcome"
    t.string "path"
    t.json "payload", default: {}
    t.string "queue_name"
    t.integer "record_link_count", default: 0, null: false
    t.string "region"
    t.string "request_id"
    t.string "request_method"
    t.string "schema_version", default: "1", null: false
    t.string "service_name"
    t.string "service_version"
    t.string "source", null: false
    t.integer "sql_count", default: 0, null: false
    t.float "sql_duration_ms", default: 0.0, null: false
    t.datetime "started_at", null: false
    t.string "status", default: "ok", null: false
    t.bigint "trace_id", null: false
    t.string "trace_type", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["account_id"], name: "index_solid_events_summaries_on_account_id"
    t.index ["caused_by_event_id"], name: "index_solid_events_summaries_on_caused_by_event_id"
    t.index ["caused_by_trace_id"], name: "index_solid_events_summaries_on_caused_by_trace_id"
    t.index ["deployment_id"], name: "index_solid_events_summaries_on_deployment_id"
    t.index ["duration_ms"], name: "index_solid_events_summaries_on_duration_ms"
    t.index ["entity_id"], name: "index_solid_events_summaries_on_entity_id"
    t.index ["entity_type"], name: "index_solid_events_summaries_on_entity_type"
    t.index ["environment_name"], name: "index_solid_events_summaries_on_environment_name"
    t.index ["error_fingerprint"], name: "index_solid_events_summaries_on_error_fingerprint"
    t.index ["http_status"], name: "index_solid_events_summaries_on_http_status"
    t.index ["queue_name"], name: "index_solid_events_summaries_on_queue_name"
    t.index ["region"], name: "index_solid_events_summaries_on_region"
    t.index ["request_id"], name: "index_solid_events_summaries_on_request_id"
    t.index ["request_method"], name: "index_solid_events_summaries_on_request_method"
    t.index ["service_name"], name: "index_solid_events_summaries_on_service_name"
    t.index ["service_version"], name: "index_solid_events_summaries_on_service_version"
    t.index ["started_at"], name: "index_solid_events_summaries_on_started_at"
    t.index ["status"], name: "index_solid_events_summaries_on_status"
    t.index ["trace_id"], name: "index_solid_events_summaries_on_trace_id", unique: true
    t.index ["user_id"], name: "index_solid_events_summaries_on_user_id"
  end

  create_table "solid_events_traces", force: :cascade do |t|
    t.bigint "caused_by_event_id"
    t.bigint "caused_by_trace_id"
    t.json "context", default: {}
    t.datetime "created_at", null: false
    t.datetime "finished_at"
    t.string "name", null: false
    t.string "source", null: false
    t.datetime "started_at", null: false
    t.string "status", default: "ok", null: false
    t.string "trace_type", null: false
    t.datetime "updated_at", null: false
    t.index ["caused_by_event_id"], name: "index_solid_events_traces_on_caused_by_event_id"
    t.index ["caused_by_trace_id"], name: "index_solid_events_traces_on_caused_by_trace_id"
    t.index ["started_at"], name: "index_solid_events_traces_on_started_at"
    t.index ["status"], name: "index_solid_events_traces_on_status"
    t.index ["trace_type"], name: "index_solid_events_traces_on_trace_type"
  end

  create_table "tags", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_tags_on_name", unique: true
    t.index ["slug"], name: "index_tags_on_slug", unique: true
  end

  create_table "uploads", force: :cascade do |t|
    t.string "agent_run_id"
    t.bigint "api_key_id", null: false
    t.datetime "applied_at"
    t.integer "base_revision_id"
    t.bigint "book_id"
    t.string "book_uid"
    t.text "build_log"
    t.datetime "created_at", null: false
    t.text "error_message"
    t.integer "expected_revision"
    t.string "parser_version", null: false
    t.jsonb "plan", default: {}, null: false
    t.jsonb "result", default: {}, null: false
    t.string "source_commit"
    t.string "source_sha256", null: false
    t.string "status", default: "received", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.jsonb "validation_errors", default: [], null: false
    t.jsonb "warnings", default: [], null: false
    t.index ["api_key_id"], name: "index_uploads_on_api_key_id"
    t.index ["base_revision_id"], name: "index_uploads_on_base_revision_id"
    t.index ["book_id"], name: "index_uploads_on_book_id"
    t.index ["book_uid"], name: "index_uploads_on_book_uid"
    t.index ["status"], name: "index_uploads_on_status"
    t.index ["user_id"], name: "index_uploads_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.string "name", null: false
    t.string "password_digest", null: false
    t.integer "role", null: false
    t.boolean "sell_paid_books"
    t.bigint "seller_attention_book_id"
    t.string "seller_attention_reason"
    t.boolean "seller_attention_required", default: false, null: false
    t.string "seller_country_code"
    t.string "slug"
    t.string "stripe_connect_account_id"
    t.boolean "stripe_connect_charges_enabled", default: false, null: false
    t.boolean "stripe_connect_details_submitted", default: false, null: false
    t.boolean "stripe_connect_payouts_enabled", default: false, null: false
    t.datetime "updated_at", null: false
    t.string "username"
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
    t.index ["name"], name: "index_users_on_name", unique: true
    t.index ["sell_paid_books"], name: "index_users_on_sell_paid_books"
    t.index ["seller_attention_book_id"], name: "index_users_on_seller_attention_book_id"
    t.index ["seller_country_code"], name: "index_users_on_seller_country_code"
    t.index ["slug"], name: "index_users_on_slug", unique: true
    t.index ["stripe_connect_account_id"], name: "index_users_on_stripe_connect_account_id", unique: true
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  add_foreign_key "accesses", "books"
  add_foreign_key "accesses", "users"
  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "agent_claims", "agents"
  add_foreign_key "agent_claims", "users", column: "claimed_by_user_id"
  add_foreign_key "agents", "users", column: "owner_user_id"
  add_foreign_key "api_key_events", "api_keys"
  add_foreign_key "api_key_events", "users"
  add_foreign_key "api_keys", "agents"
  add_foreign_key "api_keys", "users"
  add_foreign_key "book_revisions", "books"
  add_foreign_key "book_revisions", "uploads"
  add_foreign_key "book_sales", "books"
  add_foreign_key "book_sales", "pay_charges"
  add_foreign_key "book_sales", "users", column: "buyer_user_id"
  add_foreign_key "book_sales", "users", column: "seller_user_id"
  add_foreign_key "book_tags", "books"
  add_foreign_key "book_tags", "tags"
  add_foreign_key "book_units", "books"
  add_foreign_key "book_units", "leaves"
  add_foreign_key "book_views", "books"
  add_foreign_key "book_views", "users"
  add_foreign_key "books", "book_revisions", column: "current_draft_revision_id"
  add_foreign_key "books", "book_revisions", column: "published_revision_id"
  add_foreign_key "books", "categories"
  add_foreign_key "books", "users", column: "seller_user_id"
  add_foreign_key "edits", "leaves"
  add_foreign_key "idempotency_keys", "api_keys"
  add_foreign_key "identities", "users"
  add_foreign_key "leaves", "books"
  add_foreign_key "pay_charges", "pay_customers", column: "customer_id"
  add_foreign_key "pay_charges", "pay_subscriptions", column: "subscription_id"
  add_foreign_key "pay_payment_methods", "pay_customers", column: "customer_id"
  add_foreign_key "pay_subscriptions", "pay_customers", column: "customer_id"
  add_foreign_key "sessions", "users"
  add_foreign_key "solid_events_error_links", "solid_events_traces", column: "trace_id"
  add_foreign_key "solid_events_events", "solid_events_traces", column: "trace_id"
  add_foreign_key "solid_events_incident_events", "solid_events_incidents", column: "incident_id"
  add_foreign_key "solid_events_record_links", "solid_events_traces", column: "trace_id"
  add_foreign_key "solid_events_summaries", "solid_events_traces", column: "trace_id"
  add_foreign_key "uploads", "api_keys"
  add_foreign_key "uploads", "books"
  add_foreign_key "uploads", "users"
  add_foreign_key "users", "books", column: "seller_attention_book_id"
end
