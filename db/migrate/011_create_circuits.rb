class CreateCircuits < ActiveRecord::Migration
  def self.up
    create_table :circuits do |t|
      # t.column :name, :string
    end
  end

  def self.down
    drop_table :circuits
  end
end
