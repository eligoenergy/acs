class AddManagerIdToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :manager_id, :integer
    add_index :users, :manager_id
  end

  def self.down
    remove_column :users, :manager_id
    remove_index :users, :manager_id
  end
end
