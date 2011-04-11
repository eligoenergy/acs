class CreatePreferences < ActiveRecord::Migration
  def self.up
      create_table :preferences do |t|
  	  t.string :name, :null => false
  	  t.references :owner, :polymorphic => true, :null => false
  	  t.references :group, :polymorphic => true
  	  t.string :value
  	  t.timestamps
    end
  end

  def self.down
    drop_table :preferences
  end
end
