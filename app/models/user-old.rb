class User < ActiveRecord::Base
 
 self.table_name = 'mbms_user'
 belongs_to :customer
 validates_confirmation_of :password, :message => "Does not match confirmation.".t
 validates_length_of :password, :within => 3..64, :too_short => "Enter at least 3 characters".t, :too__long => "Not more than 64 characters".t
 
 
 def self.get_by_login(username, password, require_customer=false)
   c = User.find_by_username(username)
   return nil if c.nil?
#   flash[:test] = c.password.crypt(c.password) + " " + password
   
   return nil if password.crypt(c.password) != c.password
   
   if require_customer then
     return c if c.customer_id > 0
   else
     return c
   end
    return nil
 end
 

end
