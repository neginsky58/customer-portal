
# this table has wrong associations, the id should have been in
# the customer table. Access with [] from customer...
#
class CustomerMailSettings < ActiveRecord::Base
 
 self.table_name = 'customer_mail_settings'
 belongs_to :customer
 
   def has_mail?
     max_accounts > 0 || max_aliases > 0
  end

end
