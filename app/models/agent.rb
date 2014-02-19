
class Agent < ActiveRecord::Base
  
  self.table_name = 'agent'
  has_many :customers
  
  
    def x_account(x)
    a = Account.find(:first, :conditions => ['agent_id = ? and account_type = ?', self.id, x])    
    unless a
      a = Account.new
      a.agent = self
      a.root = false
      a.account_type = x
      a.save!
    end
    a
  end
  
  def sales_account
     x_account('sales')
  end

end
