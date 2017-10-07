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

ActiveRecord::Schema.define(version: 20160504073337) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "ip_addresses", force: :cascade do |t|
    t.integer  "user_id"
    t.string   "affiliation",      default: "", null: false
    t.string   "domain",           default: "", null: false
    t.string   "assigned_address", default: "", null: false
    t.string   "mac_address",      default: "", null: false
    t.datetime "created_at",                    null: false
    t.datetime "updated_at",                    null: false
    t.integer  "vlan",             default: 62, null: false
  end

  add_index "ip_addresses", ["assigned_address"], name: "index_ip_addresses_on_assigned_address", unique: true, using: :btree
  add_index "ip_addresses", ["domain", "affiliation"], name: "index_ip_addresses_on_domain_and_affiliation", unique: true, using: :btree
  add_index "ip_addresses", ["mac_address"], name: "index_ip_addresses_on_mac_address", unique: true, using: :btree
  add_index "ip_addresses", ["user_id"], name: "index_ip_addresses_on_user_id", using: :btree

  create_table "local_records", force: :cascade do |t|
    t.string   "name",          default: "",    null: false
    t.integer  "ttl",           default: 86400, null: false
    t.string   "rdtype",        default: "",    null: false
    t.string   "rdata",         default: "",    null: false
    t.integer  "ip_address_id"
    t.datetime "created_at",                    null: false
    t.datetime "updated_at",                    null: false
  end

  add_index "local_records", ["ip_address_id"], name: "index_local_records_on_ip_address_id", using: :btree

  create_table "radius_check_informations", force: :cascade do |t|
    t.string   "mac_address",      default: "",                   null: false
    t.string   "radius_attribute", default: "Cleartext-Password", null: false
    t.string   "op",               default: ":=",                 null: false
    t.string   "value",            default: ""
    t.integer  "ip_address_id"
    t.datetime "created_at",                                      null: false
    t.datetime "updated_at",                                      null: false
  end

  add_index "radius_check_informations", ["ip_address_id"], name: "index_radius_check_informations_on_ip_address_id", using: :btree
  add_index "radius_check_informations", ["mac_address", "radius_attribute"], name: "radius_check_index", using: :btree

  create_table "radius_reply_informations", force: :cascade do |t|
    t.string   "mac_address",      default: "",                     null: false
    t.string   "radius_attribute", default: "DHCP-Your-IP-Address", null: false
    t.string   "op",               default: "=",                    null: false
    t.string   "value",            default: "",                     null: false
    t.integer  "ip_address_id"
    t.datetime "created_at",                                        null: false
    t.datetime "updated_at",                                        null: false
  end

  add_index "radius_reply_informations", ["ip_address_id"], name: "index_radius_reply_informations_on_ip_address_id", using: :btree
  add_index "radius_reply_informations", ["mac_address", "radius_attribute"], name: "radius_reply_index", using: :btree

  create_table "users", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "uid",        default: "", null: false
    t.integer  "vm_limit",   default: 0,  null: false
  end

  create_table "virtual_machines", force: :cascade do |t|
    t.integer  "ip_address_id"
    t.string   "name",           default: "",   null: false
    t.string   "template_name",  default: "",   null: false
    t.datetime "created_at",                    null: false
    t.datetime "updated_at",                    null: false
    t.string   "kvm_hostname",   default: "",   null: false
    t.boolean  "cleanup_marked", default: true, null: false
  end

  add_index "virtual_machines", ["ip_address_id"], name: "index_virtual_machines_on_ip_address_id", using: :btree

  add_foreign_key "local_records", "ip_addresses"
  add_foreign_key "radius_check_informations", "ip_addresses"
  add_foreign_key "radius_reply_informations", "ip_addresses"
  add_foreign_key "virtual_machines", "ip_addresses"
end
