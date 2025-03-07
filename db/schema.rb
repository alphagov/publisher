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

ActiveRecord::Schema[7.1].define(version: 2025_02_28_161852) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "artefact_actions", force: :cascade do |t|
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
    t.string "title"
    t.string "url"
    t.bigint "artefact_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
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
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name", "state", "kind", "id"], name: "index_artefacts_on_name_and_state_and_kind_and_id"
    t.index ["slug"], name: "index_artefacts_on_slug", unique: true
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
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["disabled"], name: "index_users_on_disabled"
  end

  add_foreign_key "artefact_actions", "artefacts"
  add_foreign_key "artefact_actions", "users"
  add_foreign_key "artefact_external_links", "artefacts"
end
