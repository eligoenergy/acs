class AddCurrentStateToResources < ActiveRecord::Migration
  def self.up
    add_column :resources, :current_state, :string, :default => 'active', :null => false
  end

  def self.down
    remove_column :resources, :current_state
  end
end
