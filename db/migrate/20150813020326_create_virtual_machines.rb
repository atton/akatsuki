class CreateVirtualMachines < ActiveRecord::Migration
  def change
    create_table :virtual_machines do |t|
      t.references :ip_address,    index: true, foreign_key: true
      t.string     :name,          null: false, default: ''
      t.string     :template_name, null: false, default: ''

      t.timestamps null: false
    end
  end
end
