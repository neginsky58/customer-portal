class CreateCustomerMailSettings < ActiveRecord::Migration
  def self.up
    create_table :customer_mail_settings do |t|
      # t.column :name, :string
    end
  end

  def self.down
    drop_table :customer_mail_settings
  end
end
