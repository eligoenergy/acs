class CreateRoles < ActiveRecord::Migration
  def self.up
    create_table :roles do |t|
      t.string :name, :null => false
    end
    Role.reset_column_information
    Role::ROLES.each do |role|
      Role.create(:name => role)
    end
    add_index :roles, :name
  end

  def self.down
    drop_table :roles
  end
end
