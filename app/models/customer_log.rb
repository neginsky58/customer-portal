class CustomerLog < ActiveRecord::Base
 
 self.table_name = 'log_customer'
 belongs_to :customer
 belongs_to :user

 def before_create
   self.created = Time.now
 end
 
 def user_permission?(user)
   if self.access_role then
      return user.permission_to?("a|r,#{self.access_role},")
   end
   true
 end

end

