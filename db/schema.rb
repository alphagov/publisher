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

ActiveRecord::Schema[7.1].define(version: 2024_12_11_110046) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "actions", force: :cascade do |t|
    t.integer "approver_id"
    t.datetime "approved"
    t.string "edition_id"
    t.string "comment"
    t.string "requester_id"
    t.boolean "comment_sanitized"
    t.string "request_type"
    t.json "request_details"
    t.string "email_addresses"
    t.string "customised_message"
    t.datetime "created_at"
  end

  create_table "answer_editions", force: :cascade do |t|
    t.string "body"
  end

  create_table "artefact_actions", force: :cascade do |t|
    t.string "action_type"
    t.json "snapshot"
    t.string "task_performed_by"
  end

  create_table "artefacts", force: :cascade do |t|
    t.string "name"
    t.string "slug"
    t.string "paths"
    t.string "prefixes"
    t.string "kind"
    t.string "owning_app"
    t.string "rendering_app"
    t.string "_type"
    t.boolean "active", default: false
    t.string "publication_id"
    t.string "description"
    t.string "state", default: "draft"
    t.string "language", default: "en"
    t.string "latest_change_note"
    t.datetime "public_timestamp"
    t.string "redirect_url"
    t.string "content_id"
    t.index ["kind"], name: "index_artefacts_on_kind"
    t.index ["name"], name: "index_artefacts_on_name"
    t.index ["slug"], name: "index_artefacts_on_slug", unique: true
    t.index ["state"], name: "index_artefacts_on_state"
  end

  create_table "editions", force: :cascade do |t|
    t.string "panopticon_id"
    t.integer "version_number"
    t.string "editionable_type", null: false
    t.bigint "editionable_id", null: false
    t.integer "sibling_in_progress"
    t.string "title"
    t.boolean "in_beta", default: false
    t.datetime "created_at"
    t.datetime "publish_at"
    t.string "overview"
    t.string "slug"
    t.integer "rejected_count", default: 0
    t.string "assignee"
    t.string "state"
    t.string "reviewer"
    t.string "creator"
    t.string "publisher"
    t.string "archiver"
    t.boolean "major_change", default: false
    t.string "change_note"
    t.datetime "review_requested_at"
    t.string "auth_bypass_id", default: "53d67f8b-9560-4c4a-a9d3-45d8741e803d"
    t.string "owning_org_content_ids"
    t.index ["created_at"], name: "index_editions_on_created_at"
    t.index ["editionable_type", "editionable_id"], name: "index_editions_on_editionable"
    t.index ["panopticon_id"], name: "index_editions_on_panopticon_id", unique: true
    t.index ["version_number"], name: "index_editions_on_version_number", unique: true
  end

  create_table "guide_editions", force: :cascade do |t|
    t.string "video_url"
    t.string "video_summary"
    t.boolean "hide_chapter_navigation"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "parts", force: :cascade do |t|
    t.integer "order"
    t.string "title"
    t.string "body"
    t.string "slug"
    t.datetime "created_at", default: "2024-12-11 11:04:21"
  end

  create_table "users", force: :cascade do |t|
    t.string "name"
    t.string "email"
    t.string "uid"
    t.string "organisation_slug"
    t.string "organisation_content_id"
    t.string "app_name"
    t.text "permissions"
    t.boolean "remotely_signed_out", default: false
    t.boolean "disabled", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

end
