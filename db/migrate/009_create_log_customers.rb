class CreateLogCustomers < ActiveRecord::Migration
  def self.up
    create_table :log_customers do |t|
      # t.column :name, :string
    end
  end

  def self.down
    drop_table :log_customers
  end
end
