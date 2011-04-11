class ConvertChangeLogColumnsToText < ActiveRecord::Migration
  def self.up
    change_column :change_logs, :old_value, :text
    change_column :change_logs, :new_value, :text
  end

  def self.down
    change_column :change_logs, :old_value, :string
    change_column :change_logs, :new_value, :string
  end
end
