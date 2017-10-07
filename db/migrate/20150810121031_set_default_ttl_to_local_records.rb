class SetDefaultTtlToLocalRecords < ActiveRecord::Migration
  def up
    change_column(:local_records, :ttl, :integer, null: false, default: 24.hours.to_i)
  end
  def down
    change_column(:local_records, :ttl, :integer, null: false, default: 0)
  end
end
