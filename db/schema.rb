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

ActiveRecord::Schema[8.1].define(version: 2026_04_17_174205) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "games", force: :cascade do |t|
    t.jsonb "config"
    t.datetime "created_at", null: false
    t.string "name"
    t.datetime "updated_at", null: false
  end

  create_table "room_memberships", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "room_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["room_id"], name: "index_room_memberships_on_room_id"
    t.index ["user_id"], name: "index_room_memberships_on_user_id"
  end

  create_table "rooms", force: :cascade do |t|
    t.bigint "admin_id", null: false
    t.string "code"
    t.jsonb "config"
    t.datetime "created_at", null: false
    t.bigint "game_id", null: false
    t.bigint "squad_id"
    t.string "status"
    t.datetime "updated_at", null: false
    t.index ["admin_id"], name: "index_rooms_on_admin_id"
    t.index ["game_id"], name: "index_rooms_on_game_id"
    t.index ["squad_id"], name: "index_rooms_on_squad_id"
  end

  create_table "rounds", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "room_id", null: false
    t.integer "round_number"
    t.datetime "updated_at", null: false
    t.index ["room_id"], name: "index_rounds_on_room_id"
  end

  create_table "scores", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "points"
    t.bigint "scoreable_id", null: false
    t.string "scoreable_type", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["scoreable_type", "scoreable_id"], name: "index_scores_on_scoreable"
    t.index ["user_id"], name: "index_scores_on_user_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "squad_memberships", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "squad_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["squad_id"], name: "index_squad_memberships_on_squad_id"
    t.index ["user_id"], name: "index_squad_memberships_on_user_id"
  end

  create_table "squads", force: :cascade do |t|
    t.bigint "admin_id", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name"
    t.datetime "updated_at", null: false
    t.index ["admin_id"], name: "index_squads_on_admin_id"
  end

  create_table "turns", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "ended_at"
    t.bigint "round_id", null: false
    t.datetime "started_at"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.string "word"
    t.index ["round_id"], name: "index_turns_on_round_id"
    t.index ["user_id"], name: "index_turns_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.datetime "updated_at", null: false
    t.string "username", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "room_memberships", "rooms"
  add_foreign_key "room_memberships", "users"
  add_foreign_key "rooms", "games"
  add_foreign_key "rooms", "squads"
  add_foreign_key "rooms", "users", column: "admin_id"
  add_foreign_key "rounds", "rooms"
  add_foreign_key "scores", "users"
  add_foreign_key "sessions", "users"
  add_foreign_key "squad_memberships", "squads"
  add_foreign_key "squad_memberships", "users"
  add_foreign_key "squads", "users", column: "admin_id"
  add_foreign_key "turns", "rounds"
  add_foreign_key "turns", "users"
end
