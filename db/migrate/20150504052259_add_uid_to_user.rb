class AddUidToUser < ActiveRecord::Migration
  def up
    add_column    :users, :uid, :string
    change_column :users, :uid, :string, null: false
  end

  def down
    remove_column :users, :uid
  end
end
