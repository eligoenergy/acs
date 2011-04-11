class UpdatePermissions < ActiveRecord::Migration
  def self.up
    add_column :permission_types, :resource_group_id, :integer
  end

  def self.down
    remove_column :permission_types, :resource_group_id
  end
end
