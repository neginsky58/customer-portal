class Ip < ActiveRecord::Base
   
   self.table_name = 'ip'
   belongs_to :ip_network, :foreign_key => 'network_id'
   has_many :ip_logs
   
   def log(message)
     IpLog.create(:ip_id => self.id, :created => Time.now, :message => message)
   end

   def self.ip_to_int(ip)
     i = 1
     ip.split('.').map {|e| e.to_i}.reverse.inject(0) { |m,e| m += e*i; i*=256; m }
   end

 
   before_save do |record|
     record.address_i = Ip.ip_to_int(record.address)
   end
   
   def next_free
      Ip.find(:first, :conditions => 
         ['address_i > ? AND service = ? and network_id is null', self.address_i, self.service], :order => 'address_i')            
   end
   
   # get next ip that is assigned to a network
   def next_assigned
      Ip.find(:first, :conditions => 
        ['address_i > ? AND service = ? and network_id is not null', self.address_i, self.service], :order => 'address_i asc')
   end
   
   # get next ip that is either assigned to a network or marked as reserved
   def next_assigned_or_reserved
      Ip.find(:first, :conditions => 
        ['address_i > ? AND service = ? and (network_id is not null OR reserved_until is not null)', 
         self.address_i, self.service], :order => 'address_i asc')
   end

   
   def unique_reserved_id
      "#{reserved_until}-#{reserved_by}-#{reserved_reason}"
   end
   
   def unique_group_id
      self.reserved? ? unique_reserved_id : self.network_id
   end
   
   def free?
      (!reserved? && !network_id)
   end
   
   def reserved?
      !self.reserved_until.nil?
   end
   
   # reserve block of ip's
   def self.reserve(ip_addr, reserved_by, reserved_until, reserved_reason)
      first = ip_addr.to_range.to_a.first.address_i
      last = ip_addr.to_range.to_a.last.address_i

      Ip.transaction do      
      Ip.find(:all, :conditions => ["address_i >= ? and address_i <= ?", first,last]).each do |ip|
           ip.reserved_until = reserved_until
           ip.reserved_by = reserved_by.id
           ip.reserved_reason = reserved_reason
           ip.log("Reserved by #{reserved_by.username}")
	   ip.save
      end
      end
   end

   # get next ip that that has a different reservation status
   def next_diff_reserved
     if self.reserved_until then
        Ip.find(:first, :conditions =>
           ['address_i > ? AND ((reserved_until != ? OR reserved_until is null) AND 
                                (reserved_by != ? or reserved_by is null) AND
                                (reserved_reason != ? or reserved_reason is null))',
           self.address_i, self.reserved_until, self.reserved_by, self.reserved_reason], :order => 'address_i')
     else
        Ip.find(:first, :conditions => ['reserved_until is not null'])
     end
   end
   
   def generate_ptr
      return nil unless self.ip_network		# only resolve assigned IP's
      net_name = self.ip_network.short_name
      idx = self.address_i - self.ip_network.to_ipaddr.to_i
      return "#{self.service[0..2].downcase}-#{idx}.#{net_name}"
   end

   def to_ipaddr
      require 'ip_addr'
      if ip_network then
        IPAddr.new("#{self.address}/#{self.ip_network.mask}")
      else
        IPAddr.new("#{self.address}/32")
      end
   end

end

