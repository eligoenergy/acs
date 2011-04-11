class CreateEmploymentTypes < ActiveRecord::Migration
  def self.up
    create_table :employment_types do |t|
      t.string :name
      t.timestamps
    end
    add_index :employment_types, :name
    add_column :users, :employment_type_id, :integer
    add_index :users, :employment_type_id
  end

  def self.down
    drop_table :employment_types
    remove_column :users, :employment_type_id
  end
end
