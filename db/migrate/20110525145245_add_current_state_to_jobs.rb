class AddCurrentStateToJobs < ActiveRecord::Migration
  def self.up
    add_column :jobs, :current_state, :string, :default => 'active', :null => false
  end

  def self.down
    remove_column :jobs, :current_state
  end
end
