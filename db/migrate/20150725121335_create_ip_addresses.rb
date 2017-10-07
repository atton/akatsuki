class CreateIpAddresses < ActiveRecord::Migration
  def change
    create_table :ip_addresses do |t|
      t.references :user
      t.string :affiliation,      null:false, default: ''
      t.string :domain,           null:false, default: ''
      t.string :assigned_address, null:false, default: ''
      t.string :mac_address,      null:false, default: ''

      t.timestamps null: false
    end
    add_index :ip_addresses, :user_id
    add_index :ip_addresses, :assigned_address,       unique: true
    add_index :ip_addresses, :mac_address,            unique: true
    add_index :ip_addresses, [:domain, :affiliation], unique: true
  end
end
