
class Account < ActiveRecord::Base
 
 self.table_name = 'accounts'

 has_many :transactions
 belongs_to :agent
 belongs_to :customer
 belongs_to :user
 
 def hname
   if root then
      return agent ? "Root Agent #{agent.hid}: #{account_type}" : "Root #{account_type}"
   end
   if user then
      return "User #{user.username}: #{account_type}"
   end
   if agent then
      return "Agent #{agent.hid}: #{account_type}"
   end
   return "Customer #{customer.hid}: #{account_type}"
 end
 
 def trans(amount, balance_to, journal, options = {})
   raise ArgumentError, "Balance to account" unless balance_to.instance_of?(Account)
   raise ArgumentError, "Need to know Journal" unless journal.instance_of?(Journal)
   Transaction.transaction do
       t = Transaction.new
       t.account = self
       t.amount = amount
       t.journal = journal
       t.invoice_item_id = options[:invoice_item_id]
       t.save
       t2 = Transaction.new
       t2.account = balance_to
       t2.amount = -(amount)
       t2.journal = journal
       t2.invoice_item_id = options[:invoice_item_id]
       t2.save
   end
   balance_to.reload
   self.reload
 end
 
 def credit(amount, balance_to, journal, options = {})
    trans(-amount, balance_to, journal, options)
 end

 def debit(amount, balance_to, journal, options = {})
    trans(amount, balance_to, journal, options)
 end

 # find or create a 'root_affiliate' account
 def self.root_agent(agent)
    ac = Account.find(:first, :conditions => 
             ["agent_id = ? and account_type = 'root_agent' and customer_id is null and root = ?", agent.id, true] )
    unless ac
      ac = Account.new
      ac.account_type = 'root_agent'
      ac.agent_id = agent.id
      ac.root = true
      ac.customer_id = nil
      ac.save!
    end
    ac
 end

 
 def self.root_x_account(x)
    a = Account.find(:first, :conditions => ['agent_id is null and customer_id is null '+
                                             'and account_type = ? and root = ?',
                  x, true])    
    unless a
      a = Account.new
      a.agent = nil
      a.customer = nil
      a.account_type = x
      a.root = true
      a.save!
    end
    a
  end
  
  def self.root_sales
    root_x_account('sales')
  end
  
  def self.root_cos
    root_x_account('cos')
  end
  
  def self.root_cash
    root_x_account('cash')
  end



end

