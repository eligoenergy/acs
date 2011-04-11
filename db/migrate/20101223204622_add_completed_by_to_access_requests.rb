class AddCompletedByToAccessRequests < ActiveRecord::Migration
  def self.up
    add_column :access_requests, :completed_by_id, :integer
  end

  def self.down
    remove_column :access_requests, :completed_by_id
  end
end
