class LogCustomer < ActiveRecord::Base
 
 self.table_name = 'log_customer'
 belongs_to :user
 belongs_to :customer
end
