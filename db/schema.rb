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

ActiveRecord::Schema[7.1].define(version: 2025_08_27_080300) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pgcrypto"
  enable_extension "plpgsql"

  create_table "actions", force: :cascade do |t|
    t.integer "approver_id"
    t.datetime "approved"
    t.string "comment"
    t.boolean "comment_sanitized", default: false
    t.string "request_type"
    t.jsonb "request_details", default: {}
    t.string "email_addresses"
    t.string "customised_message"
    t.text "mongo_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "edition_id"
    t.bigint "requester_id"
    t.bigint "recipient_id"
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
    t.text "mongo_id"
    t.string "action_type"
    t.jsonb "snapshot"
    t.string "task_performed_by"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.bigint "artefact_id"
    t.index ["artefact_id"], name: "index_artefact_actions_on_artefact_id"
    t.index ["user_id"], name: "index_artefact_actions_on_user_id"
  end

  create_table "artefact_external_links", force: :cascade do |t|
    t.text "mongo_id"
    t.string "title"
    t.string "url"
    t.bigint "artefact_id"
    t.index ["artefact_id"], name: "index_artefact_external_links_on_artefact_id"
  end

  create_table "artefacts", force: :cascade do |t|
    t.string "name"
    t.string "slug"
    t.string "paths", default: [], array: true
    t.string "prefixes", default: [], array: true
    t.string "kind"
    t.string "owning_app"
    t.string "rendering_app"
    t.boolean "active", default: false
    t.string "publication_id"
    t.string "description"
    t.string "state", default: "draft"
    t.string "language", default: "en"
    t.string "latest_change_note"
    t.datetime "public_timestamp"
    t.string "redirect_url"
    t.string "content_id"
    t.text "mongo_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name", "state", "kind", "id"], name: "index_artefacts_on_name_and_state_and_kind_and_id"
    t.index ["slug"], name: "index_artefacts_on_slug", unique: true
  end

  create_table "campaign_editions", force: :cascade do |t|
    t.string "body"
    t.string "organisation_formatted_name"
    t.string "organisation_url"
    t.string "organisation_brand_colour"
    t.string "organisation_crest"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "completed_transaction_editions", force: :cascade do |t|
    t.string "body"
    t.json "presentation_toggles", default: {"promotion_choice"=>{"choice"=>"none", "url"=>""}}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "devolved_administration_availabilities", force: :cascade do |t|
    t.string "authority_type", default: "local_authority_service"
    t.string "alternative_url"
    t.string "type"
    t.text "mongo_id"
    t.bigint "local_transaction_edition_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["local_transaction_edition_id"], name: "idx_on_local_transaction_edition_id_ebafa42399"
  end

  create_table "downtimes", force: :cascade do |t|
    t.string "message"
    t.datetime "start_time"
    t.datetime "end_time"
    t.bigint "artefact_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["artefact_id"], name: "index_downtimes_on_artefact_id"
  end

  create_table "editions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "panopticon_id"
    t.integer "version_number", default: 1
    t.integer "sibling_in_progress"
    t.string "title"
    t.boolean "in_beta", default: false
    t.datetime "publish_at"
    t.string "overview"
    t.string "slug"
    t.integer "rejected_count", default: 0
    t.string "assignee"
    t.string "reviewer"
    t.string "creator"
    t.string "publisher"
    t.string "archiver"
    t.boolean "major_change", default: false
    t.string "change_note"
    t.string "state", default: "draft"
    t.datetime "review_requested_at"
    t.uuid "auth_bypass_id", default: -> { "gen_random_uuid()" }
    t.string "owning_org_content_ids", default: [], array: true
    t.text "mongo_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "editionable_type", null: false
    t.bigint "editionable_id", null: false
    t.bigint "assigned_to_id"
    t.index ["assigned_to_id"], name: "index_editions_on_assigned_to_id"
    t.index ["created_at"], name: "index_editions_on_created_at"
    t.index ["editionable_type", "editionable_id"], name: "index_editions_on_editionable"
    t.index ["panopticon_id", "version_number"], name: "index_editions_on_panopticon_id_and_version_number", unique: true
    t.index ["state"], name: "index_editions_on_state"
    t.index ["updated_at"], name: "index_editions_on_updated_at"
  end

  create_table "guide_editions", force: :cascade do |t|
    t.string "video_url"
    t.string "video_summary"
    t.boolean "hide_chapter_navigation"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "help_page_editions", force: :cascade do |t|
    t.string "body"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "licence_editions", force: :cascade do |t|
    t.string "licence_identifier"
    t.string "licence_short_description"
    t.string "licence_overview"
    t.string "will_continue_on"
    t.string "continuation_link"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "link_check_reports", force: :cascade do |t|
    t.text "mongo_id"
    t.integer "batch_id"
    t.string "status"
    t.datetime "completed_at"
    t.uuid "edition_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["batch_id"], name: "index_link_check_reports_on_batch_id", unique: true
    t.index ["edition_id"], name: "index_link_check_reports_on_edition_id"
  end

  create_table "links", force: :cascade do |t|
    t.text "mongo_id"
    t.string "uri"
    t.string "status"
    t.datetime "checked_at"
    t.text "check_warnings", default: [], array: true
    t.text "check_errors", default: [], array: true
    t.string "problem_summary"
    t.string "suggested_fix"
    t.bigint "link_check_report_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["link_check_report_id"], name: "index_links_on_link_check_report_id"
  end

  create_table "local_services", force: :cascade do |t|
    t.string "description"
    t.integer "lgsl_code"
    t.text "mongo_id"
    t.string "providing_tier", default: [], array: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["lgsl_code"], name: "index_local_services_on_lgsl_code", unique: true
  end

  create_table "local_transaction_editions", force: :cascade do |t|
    t.integer "lgsl_code"
    t.integer "lgil_override"
    t.integer "lgil_code"
    t.string "introduction"
    t.string "more_information"
    t.string "need_to_know"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "cta_text"
    t.string "before_results"
    t.string "after_results"
  end

  create_table "overview_dashboards", force: :cascade do |t|
    t.text "mongo_id"
    t.string "dashboard_type"
    t.string "result_group"
    t.integer "count"
    t.integer "draft"
    t.integer "amends_needed"
    t.integer "in_review"
    t.integer "ready"
    t.integer "fact_check_received"
    t.integer "fact_check"
    t.integer "published"
    t.integer "archived"
  end

  create_table "parts", force: :cascade do |t|
    t.text "mongo_id"
    t.integer "order"
    t.string "title"
    t.string "body"
    t.string "slug"
    t.bigint "guide_edition_id"
    t.bigint "programme_edition_id"
    t.datetime "created_at"
    t.index ["guide_edition_id"], name: "index_parts_on_guide_edition_id"
    t.index ["programme_edition_id"], name: "index_parts_on_programme_edition_id"
  end

  create_table "place_editions", force: :cascade do |t|
    t.string "introduction"
    t.string "more_information"
    t.string "need_to_know"
    t.string "place_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "popular_links_editions", force: :cascade do |t|
    t.jsonb "link_items"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "programme_editions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "simple_smart_answer_edition_node_options", force: :cascade do |t|
    t.string "label"
    t.string "slug"
    t.string "next_node"
    t.integer "order"
    t.text "mongo_id"
    t.bigint "node_id"
    t.index ["node_id"], name: "index_simple_smart_answer_edition_node_options_on_node_id"
  end

  create_table "simple_smart_answer_edition_nodes", force: :cascade do |t|
    t.string "slug"
    t.string "title"
    t.text "body"
    t.integer "order"
    t.string "kind"
    t.text "mongo_id"
    t.bigint "simple_smart_answer_edition_id"
    t.index ["simple_smart_answer_edition_id"], name: "idx_on_simple_smart_answer_edition_id_43adae8a85"
  end

  create_table "simple_smart_answer_editions", force: :cascade do |t|
    t.string "body"
    t.string "start_button_text", default: "Start now"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "transaction_editions", force: :cascade do |t|
    t.string "introduction"
    t.string "will_continue_on"
    t.string "link"
    t.string "more_information"
    t.string "need_to_know"
    t.string "alternate_methods"
    t.string "start_button_text", default: "Start now"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.string "name"
    t.string "email"
    t.string "uid"
    t.string "organisation_slug"
    t.string "organisation_content_id"
    t.string "app_name"
    t.string "permissions", default: [], array: true
    t.boolean "remotely_signed_out", default: false
    t.boolean "disabled", default: false
    t.text "mongo_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["disabled"], name: "index_users_on_disabled"
  end

  create_table "variants", force: :cascade do |t|
    t.text "mongo_id"
    t.integer "order"
    t.string "title"
    t.string "slug"
    t.string "introduction"
    t.string "link"
    t.string "more_information"
    t.string "alternate_methods"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "video_editions", force: :cascade do |t|
    t.string "video_url"
    t.string "video_summary"
    t.string "body"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
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
