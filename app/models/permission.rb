
class Permission < ActiveRecord::Base
 has_many :user_permissions

 # generates possible pstrings permissions
 def pstrings
   res = []
   (roles || '').split(//).each do |role|
     (flags || '').split(//).each do |flag|
          res << "#{role},#{name},#{flag}"
     end
   end
   res
 end

 # all possible permission strings
 def self.all_pstrings()
   res = []
   Permission.find(:all).each do |permission|
     res = res + permission.pstrings
   end
   res
 end
 
 def self.pstrings_for(user, possible=false)
   ps = Permission.all_pstrings.delete_if { |ps| !user.permission_to?(ps, :possible=>!!possible) }
   # filter for agent features enabled
   ps.find_all do |pstring|
     next true unless pstring =~ /.+?,(.+?),.*/
     middle_part = $1
     p = Permission.find_by_name(middle_part)
     if p.require_agent_feature then
       next false unless user.agent_feature?(p.require_agent_feature)
     end
     true     
   end
 end
 
 def available_for?(user)
    roles.include?(user.role)
 end

end

