class CreateRadiusCheckInformations < ActiveRecord::Migration
  def change
    create_table :radius_check_informations do |t|
      t.string     :mac_address,      null:false, default: ''
      t.string     :radius_attribute, null:false, default: 'Cleartext-Password'
      t.string     :op,               null:false, default: ':='
      t.string     :value,                        default: ''
      t.references :ip_address,       index:true, foreign_key:true

      t.timestamps null: false
    end
    add_index :radius_check_informations, [:mac_address, :radius_attribute], name: 'radius_check_index'
  end
end
