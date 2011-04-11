class AddApprovedByIdToPermissions < ActiveRecord::Migration
  def self.up
    add_column :permission_requests, :approved_by_id, :integer
  end

  def self.down
    remove_column :permission_requests, :approved_by_id
  end
end
