class AddSubmittedByIdToUser < ActiveRecord::Migration
  def self.up
    add_column :users, :submitted_by_id, :integer
  end

  def self.down
    remove_column :users, :submitted_by_id
  end
end
