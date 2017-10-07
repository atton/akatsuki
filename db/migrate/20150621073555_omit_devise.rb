class OmitDevise < ActiveRecord::Migration
  def up
    remove_column :users, :login
    remove_column :users, :uid
    remove_column :users, :remember_created_at
    remove_column :users, :sign_in_count
    remove_column :users, :current_sign_in_at
    remove_column :users, :last_sign_in_at
    remove_column :users, :current_sign_in_ip
    remove_column :users, :last_sign_in_ip

    add_column    :users, :uid, :string, default: '', null: false, unique: true
  end

  def down
    remove_column :users, :uid

    add_column :users, :login,               :string,  default: '', null: false
    add_column :users, :remember_created_at, :datetime
    add_column :users, :sign_in_count,       :integer, default: 0,  null:false
    add_column :users, :current_sign_in_at,  :datetime
    add_column :users, :last_sign_in_at,     :datetime
    add_column :users, :current_sign_in_ip,  :string
    add_column :users, :last_sign_in_ip,     :string
    add_column :users, :uid,                 :string,  default: '', null: false
  end
end
