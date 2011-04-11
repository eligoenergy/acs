class AddForNewEmployeeToAccessRequests < ActiveRecord::Migration
  def self.up
    add_column :access_requests, :for_new_user, :boolean, :default => false
  end

  def self.down
    remove_column :access_requests, :for_new_user
  end
end
