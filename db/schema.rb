# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20171025080850) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "arbitrage_periods", force: :cascade do |t|
    t.string "buy_stock_code"
    t.string "sell_stock_code"
    t.string "target_code"
    t.string "base_code"
    t.datetime "started_at"
    t.datetime "finished_at"
    t.integer "duration"
    t.float "max_revenue"
    t.float "volume"
    t.float "max_arbitrage"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "arbitrage_points", force: :cascade do |t|
    t.integer "arbitrage_period_id"
    t.datetime "time"
    t.float "max_revenue"
    t.float "volume"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "currencies", id: false, force: :cascade do |t|
    t.string "code", null: false
    t.boolean "active", default: false
    t.index ["code"], name: "index_currencies_on_code", unique: true
  end

  create_table "glasses", force: :cascade do |t|
    t.string "stock_code"
    t.string "target_code"
    t.string "base_code"
    t.text "buy_orders"
    t.text "sell_orders"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "time"
    t.index ["base_code"], name: "index_glasses_on_base_code"
    t.index ["stock_code"], name: "index_glasses_on_stock_code"
    t.index ["target_code"], name: "index_glasses_on_target_code"
    t.index ["time"], name: "index_glasses_on_time"
  end

  create_table "stock_currencies", force: :cascade do |t|
    t.string "stock_code", null: false
    t.string "stock_currency_code", null: false
    t.string "app_currency_code", null: false
    t.index ["stock_code", "app_currency_code"], name: "index_stock_currencies_on_stock_code_and_app_currency_code", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.inet "current_sign_in_ip"
    t.inet "last_sign_in_ip"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "stock_currencies", "currencies", column: "app_currency_code", primary_key: "code"
end
