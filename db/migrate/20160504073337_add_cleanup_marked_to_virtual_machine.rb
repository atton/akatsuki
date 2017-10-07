class AddCleanupMarkedToVirtualMachine < ActiveRecord::Migration
  def change
    add_column :virtual_machines, :cleanup_marked, :bool, null: false, default: true
  end
end
