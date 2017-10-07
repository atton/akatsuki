class CreateRadiusReplyInformations < ActiveRecord::Migration
  def change
    create_table :radius_reply_informations do |t|
      t.string :mac_address,      null:false, default:''
      t.string :radius_attribute, null:false, default:'DHCP-Your-IP-Address'
      t.string :op,               null:false, default: '='
      t.string :value,            null:false, default: ''
      t.references :ip_address,   index:true, foreign_key: true

      t.timestamps null: false
    end
    add_index :radius_reply_informations, [:mac_address, :radius_attribute], name: 'radius_reply_index'
  end
end
