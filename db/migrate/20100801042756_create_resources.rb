class CreateResources < ActiveRecord::Migration
  def self.up
    create_table :resources do |t|
      t.string :name, :null => false
      t.timestamps
    end
    add_index :resources, :name
  end

  def self.down
    drop_table :resources
  end
end
