
class UserInconsitentError < StandardError ; end

class User < ActiveRecord::Base
 validates_uniqueness_of :username
 validates_length_of :username, :within => 3..32
 validates_length_of :password, :within => 4..32

 validates_presence_of :fullname
 #set_table_name 'mbms_user'
 self.table_name = 'mbms_user'
 has_many :user_permissions
 has_many :settings
 
 belongs_to :agent
 belongs_to :customer
 
 has_many :stock
 
 attr :permission_to_error
 
 alias :permissions :user_permissions

 alias :old_agent :agent
 
 validates_confirmation_of :password, :message => _("Does not match confirmation.")

 
  def validate 
     errors.add :username, _("Invalid characters") unless username.gsub(/[^a-z0-9\-\_]/, '') == username     
 end
 
 private 
 def uassert(m, message)
   raise UserInconsitentError.new("User #{username} inconsitent: " + message) unless m
 end
 
 # integraty checker
 public
 def self.after_initialize
   # validate consistency of a user record
   return if new_record?
   begin
       self.role
       self.customer_id
       self.agent_id
   rescue ActiveRecord::MissingAttributeError 
       return
   end
   case self.role 
     when 'r' then
     	       uassert(read_attribute('agent_id') == nil, "Root but agent defined!")
               uassert(read_attribute('customer_id') == nil, "Root but customer defined")
     when 'c' then
               uassert(read_attribute('customer_id'), "Role customer but no customer")
               uassert(read_attribute('agent_id') == nil, "Customer account but agent directly defined (not via customer)")
               uassert(agent.id, "Customer's agent not found (in customer)")
     when 'a' then
     	       uassert(read_attribute('customer_id') == nil, "Agent but customer assigned")
               uassert(read_attribute('agent_id'), "Agent but no agent assigned")
   end
 end
 
 def agent
   customer? ? customer.agent : old_agent
 end
 
 def match_password?(clear_pw)
   clear_pw.crypt(self.password) == self.password
 end


 # return nil if agent_id == 0
 def agent_id
   read_attribute(:agent_id) == 0 ? nil : read_attribute(:agent_id)
 end

 def root?
   self.role == 'r'
 end

 def agent?
   self.role == 'a'
 end
 
 def customer?
   self.role == 'c'
 end
 
 def self.role2name(c)
   case c 
     when 'c' then "Customer"
     when 'a' then "Agent"
     when 'r' then "Root"
   end
 end
 
 
 def type
    return "Customer" if customer?
    return "Agent" if agent?
    return "Root" if root?
    return "unknown"  
 end
 
 def permission_to?(pstring, options = {})

     possible_permission = options[:possible] || false	# will test on "possible" permissions 'warp'
       
     return true if pstring == '' || pstring == nil
     
     pstring = pstring.gsub(/\,/,', ')  #fixup
     
     if pstring.split(',').size != 3 then
       @permission_to_error = "Bad Permission String: #{pstring}"
       return false
     end
     
     (role, permission, flag) = pstring.split(',').map { |p| p.strip.downcase }

     if !role.empty? then
        pass = false
        role.split('|').each do |r|
          pass = true if self.role == r
          pass = true if (self.role == 'r' && r == 'a' && possible_permission)
        end
       
        if pass == false then
          @permission_to_error =  "Role #{role} required, but you are #{self.role}"
          return false
        end
     end
     
     # stop here if user has 'all'
     all_p = self.permissions.to_a.find { |p| p.permission.name == 'all' }
     return true if all_p


     # check for permission
     up = nil			# <= the found permission, to use later
     if !permission.empty? then
        pass = false
        permission.split('|').each do |perm|
          next if pass
#          $stderr.puts "Checking permission #{perm} in #{self.permissions.to_a.map { |p| p.name }.inspect}"
          up = self.permissions.to_a.find { |p| p.permission.name == perm }
          pass = true if up
        end
        
        if !pass then 
           @permission_to_error =  "Permission #{permission} flag #{flag} required!"
           return false
        end
     end
     
 #    $stderr.puts up.inspect
#     stop :error => up.inspect
     
     # check on flag (works only if we have a permission)
     # this will check logical OR, since we can have a user, having 'r' of something
     # and a page allowing 'rw' of any type'
     if !flag.empty? && !permission.empty? then
          if !up.flags.split(//).inject(false) {|m,e| m ||= flag.include?(e) } then
            @permission_to_error = "You need #{flag} of #{up.name}, but you only have #{up.flags}"
            return false
         end
     end
     true
 end

 # removes all permission settings
 def wipe_permissions!
   raise "Unsaved user" if self.new_record?
   UserPermission.destroy_all(:user_id => self.id)
 end

 def enable_permission(pstring)
   (r,n,f) = pstring.split(',')
   p = Permission.find_by_name(n)
   raise ArgumentError.new("Permission not found: #{n}") unless p
   raise ArgumentError.new("Permission #{pstring} unavailable for #{self.username}") unless p.available_for?(self)
   self.reload
   up = self.permissions.to_a.find { |per| per.permission.name == n }
  
   if up then
      up.flags = (up.flags.split(//) + f.split(//)).uniq.join
      up.roles = (up.roles.split(//) + r.split(//)).uniq.join
      up.save!
      return 
   else
      up = UserPermission.new
      up.permission = p
      up.user = self
      up.flags = f
      up.roles = r
      up.save!
      return
   end
 end
 

 def enabled? 
   self.enable == 1
 end
 
 def disabled? 
   self.enable == 0
 end
 
 def hname
   "#{self.username} (#{self.fullname})"
 end
 
 def setting(key)
   (Setting.find(:first, :conditions => ['user_id = ? AND key = ?', self.id, key]) || Setting.new).m_value
 end

 def set_setting(key, value)
   s = (Setting.find(:first, :conditions => ['user_id = ? AND key = ?', self.id, key]) || Setting.new)
   s.m_value = value
   s.user_id = self.id
   s.key = key
   s.save!
 end

 def self.find_agent_users(agent = nil)
    aid = agent.is_a?(Agent) ? agent.id : agent
    aid ? 
      find(:all, :conditions => ["agent_id = ? AND role='a' AND enable=1", aid], :order => 'username') :
      find(:all, :conditions => "role='a' AND enable=1", :order => 'username')   
 end
 
 def self.find_root_users
      find(:all, :conditions => "role='r' AND enable=1", :order => 'username')   
 end
 

 # account for a user
 def main_account
    a = Account.find(:first, :conditions => ['user_id = ? and account_type = ? and root = ?', self.id, 'main', false])
    
    unless a
      a = Account.new
      a.user = self
      a.account_type = 'main'
      a.root = false
      a.save!
    end
    a
 end

 # Warpper to agent.features, but allow if we are a root user
 def agent_feature?(feature)
   raise "Feature doesn't exist: '#{feature}', we have #{Agent.features.join(',')}" unless Agent.features.include?(feature)
   return true if self.root?
   agent.has_feature?(feature)
 end
 
  def self.get_by_login(username, password, require_customer=false)
   c = User.find_by_username(username)

   return nil if c.nil? or c.password.nil? or password.to_s.empty?
#  flash[:test] = c.password.crypt(c.password) + " " + password
   # _debug_pass = c.password.crypt(c.password) + " " + password
   
   
   return nil if password.crypt(c.password) != c.password
   
   return nil if c.enable == 0
   
   if require_customer then
     return c if c.customer_id > 0
   else
     return c
   end
    return nil
 end
 

end


