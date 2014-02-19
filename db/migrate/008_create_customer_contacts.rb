class CreateCustomerContacts < ActiveRecord::Migration
  def self.up
    create_table :customer_contacts do |t|
      # t.column :name, :string
    end
  end

  def self.down
    drop_table :customer_contacts
  end
end
