class CreateDomains < ActiveRecord::Migration
  def self.up
    create_table :domains do |t|
      # t.column :name, :string
    end
  end

  def self.down
    drop_table :domains
  end
end
