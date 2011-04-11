class AddLawsonCdToJobs < ActiveRecord::Migration
  def self.up
    add_column :jobs, :lawson_cd, :string
  end

  def self.down
    remove_column :jobs, :lawson_cd
  end
end
