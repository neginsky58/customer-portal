class Service < ActiveRecord::Base
 has_many :service_accounting_actual
 has_many :service_prices

 validates_presence_of   :code
 validates_uniqueness_of :code

 validate :my_validations

 # returns true if we have a valid commission setup
 def commission_setup?
     %w{agent_commission sales_commission}.inject(true) { |m,e| !self.send(e.intern).nil? }
 end

 def price_setup? # temp
     commission_setup?
 end
 
 def my_validations
      self.default_price    ||= 0
      self.cost_price       ||= 0
      
      errors.add("agent_commission", "Bad range: #{agent_commission}") if agent_commission &&
                                              (agent_commission < 0 || agent_commission > 1)
      errors.add("sales_commission", "Bad range: #{sales_commission}") if sales_commission &&
                                              (sales_commission < 0 || sales_commission > 1)
      errors.add('one_time', "Can't be one_time") if one_time && (one_time != 0 && service_type.to_s.strip != '')
 end
 
 def self.mk_code(base)
   return base unless Service.find_by_code(base)
   i = 0
   code = ''
   begin
     i+=1
     code = "#{base}-%02d" % i
   end while Service.find_by_code(code)
   code
 end

 def self.get_or_create(service_type, service_config)
    s = Service.find(:first, :conditions => ['service_type = ? and service_config = ?', service_type, service_config])
    
    return s unless s.nil?
    raise ArgumentError, "Need service_type and config but got '#{service_type}' '#{service_config}'" \
                      if (service_config.nil? || service_type.nil?)		# mandatory
    
    s = Service.new
    s.service_type = service_type
    s.service_config = service_config
    s.ctype = 'auto'
    s.code = mk_code(service_config)
    s.save!
    s
 end
 
 # returns the service object by service_type string and record_id
 def self.get_service_object(service_type, record_id)
    Customer.billable_services.find do |e| 
         e.service_type == service_type
    end.find(:first, :conditions => ['id = ?' , record_id])
 end
 
 # get the service from service object
 def self.get(from_service_object)
   get_or_create(from_service_object.class.service_type, 
                 from_service_object.service_config) rescue nil
 end
 
 def get_record(record_id)
   begin
     Object.const_get(self.service_type.classify.intern).find(record_id)
   rescue NameError
     MBMS.const_get(self.service_type.classify.intern).find(record_id)
   end
 end
 
 #### Prices ####
 # list price
 def price
   self.default_price
 end
 
 # customer price
 # LIKELY THIS WILL DISAPPEAR
# def price_for_customer(customer)
#    sp = ServicePrice.find(:first, :conditions => ['customer_id = ? and service_id = ? and record_id is null', 
#    return sp ? sp.price : self.default_price
# end
 
 # find the price for this service instance
 def price_for_record(record_id)
#    customer = get_record(record_id).customer rescue nil
#    
#    raise ArgumentError, "Can't find customer for service record: #{record_id}" unless customer
 
    rec_match = ServicePrice.find(:first, :conditions => ['service_id = ? and record_id = ?',
                             self.id, record_id])
    
    return rec_match ? rec_match.price : nil
 end

 def volume_for_record(record_id)
    rec_match = ServicePrice.find(:first, :conditions => ['service_id = ? and record_id = ?',
                             self.id, record_id])
    
    return rec_match ? rec_match.volume : nil
 end

 
 def self.get_record(service_type, record_id)
    service = nil
    begin
     service = Object.const_get(service_type.classify.intern)
    rescue NameError
     service = MBMS.const_get(service_type.classify.intern)
   end
   raise ArgumentError, "Bad Class: #{service_type}" unless \
                    Customer.billable_services.include?(service)
   service.find(record_id)
 end

 def hname
    self.code || self.service_config
 end
 
 def hservice_type
   return "Other" unless self.service_type

   service =  begin
     Object.const_get(self.service_type.classify.intern)
   rescue NameError
     MBMS.const_get(self.service_type.classify.intern)
   end 
   
   service.hname
 end
 
 def get_record(record_id)
   Service.get_record(self.service_type, record_id)
 end

end

