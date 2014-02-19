class CustomerContact < ActiveRecord::Base
 
 self.table_name = 'customer_contact'
 belongs_to :customer
 belongs_to :contact
end
