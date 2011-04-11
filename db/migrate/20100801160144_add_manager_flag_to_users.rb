class AddManagerFlagToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :manager_flag, :boolean, :default => false, :null => false
  end

  def self.down
    remove_column :users, :manager_flag
  end
end
