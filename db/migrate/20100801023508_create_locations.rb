class CreateLocations < ActiveRecord::Migration
  def self.up
    create_table :locations do |t|
      t.string :name, :null => false
      t.timestamps
    end
    add_index :locations, :name
  end

  def self.down
    drop_table :locations
  end
end
