class AddVmLimitToUser < ActiveRecord::Migration
  def change
    add_column :users, :vm_limit, :integer, default:0, null: false
  end
end
