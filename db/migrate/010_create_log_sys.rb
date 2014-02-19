class CreateLogSys < ActiveRecord::Migration
  def self.up
    create_table :log_sys do |t|
      # t.column :name, :string
    end
  end

  def self.down
    drop_table :log_sys
  end
end
