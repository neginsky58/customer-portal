class Alias < ActiveRecord::Base
 
 
 self.table_name = 'mail_alias'
 validates_presence_of :alias_list
 belongs_to :customer
  validates_length_of :email_username, :within => 2..48, :message=>_("Enter 2 to 48 characters")
  validates_format_of :email_username, :with => /^(?:[a-z0-9\.\-\_]+)$/, :message=>_("Invalid format or characters")

 
 def validate
 
   # make sure the domain is selected.. and not choosen :)
   errors.add_to_base("Please try to use the selection box.. instead of playing with the parameters.. k thx bye!") unless customer.domains.collect{|x|x.domain_name}.include?(email_domain)
 
   # we should pass email_address, the trigger will split it up
   em = email_address.to_s.empty? ? (email_username + "@" + email_domain) : email_address
   
   if new_record? && Alias.find_by_email_address(em) then
       errors.add('email_username', _("%s - Already existing Alias" % em))
   end
   if MyMail.find_by_email_address(em) then
       errors.add('email_username', _("%s - Already existing Email" % em))
   end
   self.email_address = email_username + '@' + email_domain

   err = []
   alias_list.split(',').map { |e| e.strip }.each do |e|
       err << e unless e.upcase =~ /\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}\b/
   end 
   errors.add('alias_list', _("Bad format") + ": #{err.join(', ')}") unless err.empty?
 end
end
