class CreateCustomerDomains < ActiveRecord::Migration
  def self.up
    create_table :customer_domains do |t|
      # t.column :name, :string
    end
  end

  def self.down
    drop_table :customer_domains
  end
end
