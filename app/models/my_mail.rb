class MyMail < ActiveRecord::Base

self.table_name = 'mail'

validates_numericality_of :max_msgsize, :only_integer => true, 
                          :message => _("Only numbers allowed here")
validates_confirmation_of :password, :message=>_("Passwords do not match")
validates_length_of :password, :within => 4..48
validates_length_of :email_username, :within => 2..48, :message=>_("Enter 2 to 48 characters")
validates_format_of :email_username, :with => /^(?:[a-z0-9\.\-\_]+)$/, :message=>_("Invalid format or characters")
belongs_to :customer

# validates_uniquenes_of :email_address, :email_username

 def sa_level=(level)
   level = level.to_i
   if level == 0 then
    self.antispam_enable = 0
    self.antispam_warnscore = 9
    self.antispam_rejectscore = 12
   end
   if level == 1 then
    self.antispam_enable = 1
    self.antispam_warnscore = 6
    self.antispam_rejectscore = 12
   end
   if level == 2 then
    self.antispam_enable = 1
    self.antispam_warnscore = 3
    self.antispam_rejectscore = 6
   end
   if level == 3 then
    self.antispam_enable = 1
    self.antispam_warnscore = 1
    self.antispam_rejectscore = 3
   end
 end
 
 def sa_level
   return 0 if self.antispam_enable == 0
   return 1 if self.antispam_warnscore == 6
   return 2 if self.antispam_warnscore == 3
   return 3 if self.antispam_warnscore == 1
 end
 
 def self.sa_level_name sa_level
   return _('off') if sa_level == 0
   return _('low') if sa_level == 1
   return _('medium') if sa_level == 2
   return _('high') if sa_level == 3
   return _('unknown')
 end
 
 def self.get_by_login(email, password)
   m = MyMail.find(:first, :conditions => ['email_address = ?', email])
   return nil unless m
   $stderr.puts "#{password.crypt(m.password)} - #{m.password}"
   return m if (m.password == password.crypt(m.password))
   nil
 end
 
  def validate
   forward = forward_to.split(',')
   forward.each do |f|
     if f.strip.scan(/^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i).empty? then
       errors.add('forward_to', _('Invalid format: >%s<' % f.strip))
     end
   end
   
   if forward_enable == 1 and forward_to.empty? then
    errors.add('forward_to', _("Where to forward?"))
   end
   
   if max_msgsize < 50 then
    errors.add('max_msgsize', _("Size to small".t))
   end
   if max_msgsize > 30000 then
    errors.add('max_msgsize', _("Size to big".t))
   end
   self.email_address = email_username + '@' + email_domain
   
   if self.new_record? && MyMail.find_by_email_address(self.email_address) then
    errors.add("email_username", _("Already taken"))
   end
   
   reserved_names = %w{postmaster webmaster hostmaster administrator admin}
   if reserved_names.include?(email_username.downcase) then
     errors.add('email_username', _("This name is reserved".t))
   end
 end
 
 def hflags
   r = []
   r << 'FORWARD' if self.forward_enable == 1
   r << 'AUTO REPLY' if self.autoreply_enable == 1
   r.join(' + ')
 end
 
# def password=(pass)
#  write_attribute(:password, pass)
#  write_attribute(:password_clear, pass)
# end
 

end
