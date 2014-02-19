class Circuit < ActiveRecord::Base
 
 self.table_name = 'circuit'
 
 belongs_to :customer
 has_many :ip_networks
 has_many :circuit_states
 has_many :circuit_traffic, :class_name => 'CircuitTraffic', :foreign_key => 'circuit_id'

 belongs_to :commercial_service
 has_one :circuit_payg
 

 def nice_bw
   "#{self.bandwidth_ul}k/#{self.bandwidth_dl}k"
 end
 
 def nice
   "#{self.site.capitalize} - #{self.service.capitalize} (#{self.nice_bw})"
 end

  def id_string
      cust = self.customer.nil? ? '' : self.customer.hid
      "#{cust},#{self.site},#{self.service},#{self.bandwidth_ul.to_s}-#{self.bandwidth_dl.to_s}"
  end


  # returns the active state
  def active_circuit_state
     CircuitState.find(:first, :conditions => ['circuit_id = ? and stop is null', self.id] )
  end
  
  # this price:
  def price
     commercial_service.service ? commercial_service.service.price_for_record(self.id) : nil 
  end
 
  # this volume:
  def volume
     commercial_service.service ? commercial_service.service.volume_for_record(self.id) : nil 
  end

  def is_hotspot?
    net_ids = self.ip_networks.collect{|x|x.id}
    ips = Ip.find(:all,:conditions=>["network_id IN (?)",net_ids]).collect{|x|x.address}
    self.customer.radius_clients.where(:nas_name=>ips).size > 0
  end
  
end
