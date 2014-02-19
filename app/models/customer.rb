class Customer < ActiveRecord::Base

self.table_name = 'customer'

has_many :users
has_many :customer_domains
#has_many :customer_mail_settings
has_one :customer_mail_settings

has_many :circuits
has_many :mail,:class_name=>'MyMail'
has_many :aliases

has_many :customer_domains
has_many :domains, :through => :customer_domains

has_many :customer_contacts
has_many :contacts, :through => :customer_contacts

belongs_to :agent
has_and_belongs_to_many :dial_profiles
has_many :dial_tariffs
 has_many :radius_clients

 def main_account
    a = Account.find(:first, :conditions => ['customer_id = ? and account_type = ?', self.id, 'main'])
    
    unless a
      a = Account.new
      a.customer = self
      a.account_type = 'main'
      a.root = false
      a.save!
    end
    a    
 end
 def add_log(message, options = {})
   cl = CustomerLog.new
   cl.customer = self
   cl.user_id = options[:user] ? options[:user].id : nil
   cl.id_string = options[:id_string] || ''
   cl.message = message
   cl.access_role = options[:access_role] || ''
   cl.save!
 end


 def billable_services
    res = []
    circuits.each { |c| res << c unless c.status == 'D' }
    res << customer_mail_settings if customer_mail_settings && customer_mail_settings.has_mail?
    res
 end
 
 
 
  def paginated_object_find(klass,params,sort_options,size=20,scope=:all)
    cond, @search = klass.paginated_search(params,sort_options)
    sort = sort_options[:default_sort].to_s
    sort = Customer.get_sort(params[:sort],sort_options) if params[:sort] and sort_options[:sortfields].size > 0
    incl = sort_options[:include] || [] # todo check if ok
    size = 10 if size.to_i <=0
    params[:page] ||= 1
    if sort_options[:select]
      klass.visible_for(self).select(sort_options[:select]).where(cond.to_sql).includes(incl).order(sort).paginate(:per_page=>size,:page=>params[:page])
    else
      klass.visible_for(self).where(cond.to_sql).includes(incl).order(sort).paginate(:per_page=>size,:page=>params[:page])
    end
  end

 
  def self.get_sort(sort,sort_options)
    sort_fields = sort_options[:sortfields].collect{|x| x.to_s}
    # sort could be x or x_reverse
    return sort.to_s if sort_fields.include? sort.to_s
    # sort is _reverse
    return sort.to_s.sub('_reverse','')+" DESC" if sort_fields.include? sort.sub('_reverse','').to_s
    return sort_options[:default_sort]
  end


  

end
