class UserPermission < ActiveRecord::Base
  
  self.table_name = 'user_permissions'
  belongs_to :user
  belongs_to :permission
  
  
  def name
    permission.name
  end
end

