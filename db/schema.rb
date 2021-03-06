# encoding: UTF-8
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

ActiveRecord::Schema.define(version: 20140516020454) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "agents", force: true do |t|
    t.string   "name"
    t.string   "image_url"
    t.string   "booking_number"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "booking_items", force: true do |t|
    t.integer  "agent_id",   null: false
    t.integer  "flight_id",  null: false
    t.string   "deeplink",   null: false
    t.float    "price"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "flights", force: true do |t|
    t.integer  "search_task_id"
    t.string   "origin_city",      null: false
    t.string   "destination_city", null: false
    t.datetime "departure",        null: false
    t.datetime "arrival",          null: false
    t.string   "flight_number",    null: false
    t.float    "price"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "search_tasks", force: true do |t|
    t.string   "origin_city",                   null: false
    t.string   "destination_city",              null: false
    t.string   "date",                          null: false
    t.string   "status",           default: ""
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
