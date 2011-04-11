class AddJobTemplateColumns < ActiveRecord::Migration
  def self.up
    add_column :jobs, :revision, :integer, :null => false, :default => 1
    add_column :change_logs, :revision, :integer
  end

  def self.down
    remove_column :jobs, :revision
    remove_column :change_logs, :revision
  end
end
