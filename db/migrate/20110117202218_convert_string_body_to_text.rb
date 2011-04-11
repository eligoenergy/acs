class ConvertStringBodyToText < ActiveRecord::Migration
  def self.up
    #change_column :notes, :body, :text
  end

  def self.down
    #change_column :notes, :body, :string
  end
end
