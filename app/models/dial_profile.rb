class DialProfile < ActiveRecord::Base

  self.table_name = 'dial_profiles'
  # dial profiles can be associated to customers or as fk in circuits
  
  has_and_belongs_to_many :customers
  has_many :radius_online
  
  def customer
     customers.first
  end
  
  def self.all_for_customer(customer)
    find(:all, :conditions => ["customers_dial_profiles.customer_id = ?", customer.id],
               :joins => 'left join customers_dial_profiles 
                          on dial_profiles.id = customers_dial_profiles.dial_profile_id')
  end
  
    
  def online?
      !!self.class.connection.execute("SELECT acct_session_id FROM radius_online WHERE dial_profile_id = #{self.id}").first
  end
  
  def hcredit
      if self.dial_type == 'TIME' then
         return _('EXPIRED') if self.valid_until < Time.now
         return (self.valid_until - Time.now).to_timeframe
      end
      if self.dial_type == 'RELTIME' then
         return _('EXPIRED') if self.time_credit <= 0
         return _('Time left:')+' '+(self.time_credit).to_timeframe
      end
      if self.dial_type == 'VOLUME' then
         return _('EXPIRED') if self.data_credit <= 0
         return self.data_credit.to_datasize
      end
      "unknown".t
  end
  
  
  
  def self.visible_for(user)
    return user.dial_profiles
    user.dial_profiles.where("1=0") # returning false condition to avoid exception via calling nil.. this results in ar having an empty collection
  end
  
  

  def self.paginated_search(params,search_options)
      search = {}.merge(params)
      cond = Caboose::EZ::Condition.new

      if search['query']
        cond_q = Caboose::EZ::Condition.new
        cond_q.outer = :or
        search_options[:searchfields].each do  |searchfield|
          if(searchfield.to_s.include?("\."))        
            x = searchfield.to_s.split('.')
            searchfield = x[1]
            tab = x[0].to_sym          
          else
            tab = nil
          end
          cond_x = Caboose::EZ::Condition.new tab do
            eval(searchfield.to_s.to_sym.to_s) =~ "%#{search['query']}%";
          end
          cond_x.outer = :or
          cond_q << cond_x          
        end   
        
        if search_options[:searchfields_integer]
          search_options[:searchfields_integer].each do  |searchfield|
            if(searchfield.to_s.include?("\."))        
              x = searchfield.to_s.split('.')
              searchfield = x[1]
              tab = x[0].to_sym          
            else
              tab = nil
            end
            cond_x = Caboose::EZ::Condition.new tab do
              eval(searchfield.to_s.to_sym.to_s) == search['query'].to_i if search['query'].to_i > 0
            end
            cond_x.outer = :or
            cond_q << cond_x          
          end 
        end  
        
         
      end
      cond << cond_q
      cond.outer = :and
      # custom searches
      cond.append ["#{self.table_name}.status = ?",search['status'].to_s]  if search['status']
      return cond, search
  end
    
  
end

