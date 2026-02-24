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

ActiveRecord::Schema[8.1].define(version: 2026_02_16_133713) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pgcrypto"

  create_table "actions", force: :cascade do |t|
    t.datetime "approved"
    t.integer "approver_id"
    t.string "comment"
    t.boolean "comment_sanitized", default: false
    t.datetime "created_at", null: false
    t.string "customised_message"
    t.uuid "edition_id"
    t.string "email_addresses"
    t.text "mongo_id"
    t.bigint "recipient_id"
    t.jsonb "request_details", default: {}
    t.string "request_type"
    t.bigint "requester_id"
    t.string "requester_name"
    t.datetime "updated_at", null: false
    t.index ["edition_id"], name: "index_actions_on_edition_id"
    t.index ["recipient_id"], name: "index_actions_on_recipient_id"
    t.index ["requester_id"], name: "index_actions_on_requester_id"
  end

  create_table "answer_editions", force: :cascade do |t|
    t.string "body"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "artefact_actions", force: :cascade do |t|
    t.string "action_type"
    t.bigint "artefact_id"
    t.datetime "created_at", null: false
    t.text "mongo_id"
    t.jsonb "snapshot"
    t.string "task_performed_by"
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["artefact_id"], name: "index_artefact_actions_on_artefact_id"
    t.index ["user_id"], name: "index_artefact_actions_on_user_id"
  end

  create_table "artefact_external_links", force: :cascade do |t|
    t.bigint "artefact_id"
    t.text "mongo_id"
    t.string "title"
    t.string "url"
    t.index ["artefact_id"], name: "index_artefact_external_links_on_artefact_id"
  end

  create_table "artefacts", force: :cascade do |t|
    t.boolean "active", default: false
    t.string "content_id"
    t.datetime "created_at", null: false
    t.string "description"
    t.string "kind"
    t.string "language", default: "en"
    t.string "latest_change_note"
    t.text "mongo_id"
    t.string "name"
    t.string "owning_app"
    t.string "paths", default: [], array: true
    t.string "prefixes", default: [], array: true
    t.datetime "public_timestamp"
    t.string "publication_id"
    t.string "redirect_url"
    t.string "rendering_app"
    t.string "slug"
    t.string "state", default: "draft"
    t.datetime "updated_at", null: false
    t.index ["name", "state", "kind", "id"], name: "index_artefacts_on_name_and_state_and_kind_and_id"
    t.index ["slug"], name: "index_artefacts_on_slug", unique: true
  end

  create_table "campaign_editions", force: :cascade do |t|
    t.string "body"
    t.datetime "created_at", null: false
    t.string "organisation_brand_colour"
    t.string "organisation_crest"
    t.string "organisation_formatted_name"
    t.string "organisation_url"
    t.datetime "updated_at", null: false
  end

  create_table "completed_transaction_editions", force: :cascade do |t|
    t.string "body"
    t.datetime "created_at", null: false
    t.json "presentation_toggles", default: {"promotion_choice" => {"choice" => "none", "url" => ""}}
    t.datetime "updated_at", null: false
  end

  create_table "devolved_administration_availabilities", force: :cascade do |t|
    t.string "alternative_url"
    t.string "authority_type", default: "local_authority_service"
    t.datetime "created_at", null: false
    t.bigint "local_transaction_edition_id"
    t.text "mongo_id"
    t.string "type"
    t.datetime "updated_at", null: false
    t.index ["local_transaction_edition_id"], name: "idx_on_local_transaction_edition_id_ebafa42399"
  end

  create_table "downtimes", force: :cascade do |t|
    t.bigint "artefact_id"
    t.datetime "created_at", null: false
    t.datetime "end_time"
    t.string "message"
    t.datetime "start_time"
    t.datetime "updated_at", null: false
    t.index ["artefact_id"], name: "index_downtimes_on_artefact_id"
  end

  create_table "editions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "archiver"
    t.bigint "assigned_to_id"
    t.string "assignee"
    t.uuid "auth_bypass_id", default: -> { "gen_random_uuid()" }
    t.string "change_note"
    t.datetime "created_at", null: false
    t.string "creator"
    t.bigint "editionable_id", null: false
    t.string "editionable_type", null: false
    t.boolean "in_beta", default: false
    t.boolean "major_change", default: false
    t.text "mongo_id"
    t.string "overview"
    t.string "owning_org_content_ids", default: [], array: true
    t.string "panopticon_id"
    t.datetime "publish_at"
    t.string "publisher"
    t.integer "rejected_count", default: 0
    t.datetime "review_requested_at"
    t.string "reviewer"
    t.integer "sibling_in_progress"
    t.string "slug"
    t.string "state", default: "draft"
    t.string "title"
    t.datetime "updated_at", null: false
    t.integer "version_number", default: 1
    t.index ["assigned_to_id"], name: "index_editions_on_assigned_to_id"
    t.index ["created_at"], name: "index_editions_on_created_at"
    t.index ["editionable_type", "editionable_id"], name: "index_editions_on_editionable"
    t.index ["panopticon_id", "version_number"], name: "index_editions_on_panopticon_id_and_version_number", unique: true
    t.index ["state"], name: "index_editions_on_state"
    t.index ["updated_at"], name: "index_editions_on_updated_at"
  end

  create_table "guide_editions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "hide_chapter_navigation"
    t.datetime "updated_at", null: false
    t.string "video_summary"
    t.string "video_url"
  end

  create_table "help_page_editions", force: :cascade do |t|
    t.string "body"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "licence_editions", force: :cascade do |t|
    t.string "continuation_link"
    t.datetime "created_at", null: false
    t.string "licence_identifier"
    t.string "licence_overview"
    t.string "licence_short_description"
    t.datetime "updated_at", null: false
    t.string "will_continue_on"
  end

  create_table "link_check_reports", force: :cascade do |t|
    t.integer "batch_id"
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.uuid "edition_id"
    t.text "mongo_id"
    t.string "status"
    t.datetime "updated_at", null: false
    t.index ["batch_id"], name: "index_link_check_reports_on_batch_id", unique: true
    t.index ["edition_id"], name: "index_link_check_reports_on_edition_id"
  end

  create_table "links", force: :cascade do |t|
    t.text "check_errors", default: [], array: true
    t.text "check_warnings", default: [], array: true
    t.datetime "checked_at"
    t.datetime "created_at", null: false
    t.bigint "link_check_report_id"
    t.text "mongo_id"
    t.string "problem_summary"
    t.string "status"
    t.string "suggested_fix"
    t.datetime "updated_at", null: false
    t.string "uri"
    t.index ["link_check_report_id"], name: "index_links_on_link_check_report_id"
  end

  create_table "local_services", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "description"
    t.integer "lgsl_code"
    t.text "mongo_id"
    t.string "providing_tier", default: [], array: true
    t.datetime "updated_at", null: false
    t.index ["lgsl_code"], name: "index_local_services_on_lgsl_code", unique: true
  end

  create_table "local_transaction_editions", force: :cascade do |t|
    t.string "after_results"
    t.string "before_results"
    t.datetime "created_at", null: false
    t.string "cta_text"
    t.string "introduction"
    t.integer "lgil_code"
    t.integer "lgil_override"
    t.integer "lgsl_code"
    t.string "more_information"
    t.string "need_to_know"
    t.datetime "updated_at", null: false
  end

  create_table "overview_dashboards", force: :cascade do |t|
    t.integer "amends_needed"
    t.integer "archived"
    t.integer "count"
    t.string "dashboard_type"
    t.integer "draft"
    t.integer "fact_check"
    t.integer "fact_check_received"
    t.integer "in_review"
    t.text "mongo_id"
    t.integer "published"
    t.integer "ready"
    t.string "result_group"
  end

  create_table "parts", force: :cascade do |t|
    t.string "body"
    t.datetime "created_at"
    t.bigint "guide_edition_id"
    t.text "mongo_id"
    t.integer "order"
    t.bigint "programme_edition_id"
    t.string "slug"
    t.string "title"
    t.index ["guide_edition_id"], name: "index_parts_on_guide_edition_id"
    t.index ["programme_edition_id"], name: "index_parts_on_programme_edition_id"
  end

  create_table "place_editions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "introduction"
    t.string "more_information"
    t.string "need_to_know"
    t.string "place_type"
    t.datetime "updated_at", null: false
  end

  create_table "popular_links_editions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.jsonb "link_items"
    t.datetime "updated_at", null: false
  end

  create_table "programme_editions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "simple_smart_answer_edition_node_options", force: :cascade do |t|
    t.string "label"
    t.text "mongo_id"
    t.string "next_node"
    t.bigint "node_id"
    t.integer "order"
    t.string "slug"
    t.index ["node_id"], name: "index_simple_smart_answer_edition_node_options_on_node_id"
  end

  create_table "simple_smart_answer_edition_nodes", force: :cascade do |t|
    t.text "body"
    t.string "kind"
    t.text "mongo_id"
    t.integer "order"
    t.bigint "simple_smart_answer_edition_id"
    t.string "slug"
    t.string "title"
    t.index ["simple_smart_answer_edition_id"], name: "idx_on_simple_smart_answer_edition_id_43adae8a85"
  end

  create_table "simple_smart_answer_editions", force: :cascade do |t|
    t.string "body"
    t.datetime "created_at", null: false
    t.string "start_button_text", default: "Start now"
    t.datetime "updated_at", null: false
  end

  create_table "transaction_editions", force: :cascade do |t|
    t.string "alternate_methods"
    t.datetime "created_at", null: false
    t.string "introduction"
    t.string "link"
    t.string "more_information"
    t.string "need_to_know"
    t.string "start_button_text", default: "Start now"
    t.datetime "updated_at", null: false
    t.string "will_continue_on"
  end

  create_table "users", force: :cascade do |t|
    t.string "app_name"
    t.datetime "created_at", null: false
    t.boolean "disabled", default: false
    t.string "email"
    t.text "mongo_id"
    t.string "name"
    t.string "organisation_content_id"
    t.string "organisation_slug"
    t.string "permissions", default: [], array: true
    t.boolean "remotely_signed_out", default: false
    t.string "uid"
    t.datetime "updated_at", null: false
    t.index ["disabled"], name: "index_users_on_disabled"
  end

  create_table "variants", force: :cascade do |t|
    t.string "alternate_methods"
    t.datetime "created_at", null: false
    t.string "introduction"
    t.string "link"
    t.text "mongo_id"
    t.string "more_information"
    t.integer "order"
    t.string "slug"
    t.string "title"
    t.datetime "updated_at", null: false
  end

  create_table "video_editions", force: :cascade do |t|
    t.string "body"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "video_summary"
    t.string "video_url"
  end

  add_foreign_key "actions", "editions"
  add_foreign_key "actions", "users", column: "recipient_id"
  add_foreign_key "actions", "users", column: "requester_id"
  add_foreign_key "artefact_actions", "artefacts"
  add_foreign_key "artefact_actions", "users"
  add_foreign_key "artefact_external_links", "artefacts"
  add_foreign_key "devolved_administration_availabilities", "local_transaction_editions"
  add_foreign_key "downtimes", "artefacts"
  add_foreign_key "editions", "users", column: "assigned_to_id"
  add_foreign_key "link_check_reports", "editions"
  add_foreign_key "links", "link_check_reports"
  add_foreign_key "parts", "guide_editions"
  add_foreign_key "parts", "programme_editions"
  add_foreign_key "simple_smart_answer_edition_node_options", "simple_smart_answer_edition_nodes", column: "node_id"
  add_foreign_key "simple_smart_answer_edition_nodes", "simple_smart_answer_editions"
end
