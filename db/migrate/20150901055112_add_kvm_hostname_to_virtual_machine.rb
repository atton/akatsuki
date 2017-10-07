class AddKvmHostnameToVirtualMachine < ActiveRecord::Migration
  def change
    add_column :virtual_machines, :kvm_hostname, :string, default:'', null: false
  end
end
