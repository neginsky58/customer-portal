class CustomerDomain < ActiveRecord::Base
 
 self.table_name = 'customer_domain'
 belongs_to :customer
 belongs_to :domain
end
