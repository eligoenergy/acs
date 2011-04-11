class AddHistoricalFlagToAccessRequests < ActiveRecord::Migration
  def self.up
    add_column :access_requests, :historical, :boolean, :default => false, :null => false
  end

  def self.down
    remove_column :access_requests, :historical
  end
end

