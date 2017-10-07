class CreateLocalRecords < ActiveRecord::Migration
  def change
    create_table :local_records do |t|
      t.string  :name,   default: '', null: false
      t.integer :ttl,    default: 0,  null: false
      t.string  :rdtype, default: '', null: false
      t.string  :rdata,  default: '', null: false
      t.references :ip_address, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
