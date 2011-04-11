class FixCurrentUserStateColumn < ActiveRecord::Migration
  def self.up
    change_column :users, :current_state, :string, :default => 'passive'
  end

  def self.down
  end
end
