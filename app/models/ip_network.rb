class IpNetwork < ActiveRecord::Base
   
   self.table_name = 'ip_networks'
   belongs_to :router
   belongs_to :circuit


  # all possible ip's for a customer
  def customer_ips
     a = (@ip_addr || IPAddr.new("#{address}/#{mask}")).to_range
     if a.to_a.size <= 2 then
        return [a.first]
     end
     
     ar = a.to_a
          
     ar - [ar[0], ar[-1], ar[1]] # network-descr, broadcast and first ip
  end

  def address=(addr)
    raise ArgumentError.new("Address needs to be class IPAddr") unless addr.instance_of?(IPAddr)
    @ip_addr = addr
    write_attribute(:address, addr.to_range.first.to_s)
    write_attribute(:mask, addr.mask_bits)    
  end
  
  # check if block is free
  def self.free?(addr)
    return true if addr.mask_bits < 16
    start = addr.to_range.first.address_i
    stop = addr.to_range.last.address_i
    
    n = Ip.find(:first, :conditions => ['address_i >= ? and address_i <= ? and network_id is not null', start, stop])
    return false if n
    true
  end
  
  def after_save
       first = @ip_addr.to_range.first.address_i
       last  = @ip_addr.to_range.last.address_i
       
       ActiveRecord::Base.connection.execute("update ip set network_id = #{self.id} where address_i >= #{first} and address_i <= #{last}")
  end
 
  def interface?
    self.net_type == 'INTERFACE'
  end

  def route?
    self.net_type == 'ROUTE'
  end

  def ipaddr
     IPAddr.new("#{self.address}/#{self.mask}")
  end
  

  def info_ips
    res = []
    if mask < 24 then
       res << ["#{self.address}/#{self.mask}", _('Your network')]
       return res
    end
    ips = ipaddr.to_range.to_a
    
    if mask == 32 then
       res << [ips[0], _('Your address')]
       return res 
    end
    
    if mask >= 31 && net_type == 'INTERFACE' then
       res << [ips[0], _('Your address')]
       res << [ips[1], _('Gateway')] 
       return res
    end
    if mask >= 31 && net_type == 'ROUTE' then
       res << [ips[0], _('Your address')]
       res << [ips[1], _('Your address')] 
       return res
    end

    res << [ips[0], 'Network']
    if net_type == "ROUTE" then     
     res << [ips[1], _('Your first IP')]
    else         
     res << [ips[1], _('Gateway')]
     res << [ips[2], _('Your first IP')] 
    end
    res << [ips[-2], _('Your last IP')]
    res << [ips[-1], _('Broadcast address')]   
    return res    
  end
  
  def info
   res = {}
   res[:info] = []
   res[:type] = net_type == 'INTERFACE' ? "Network" : "Static Route"
   res[:info] << 'PtP Link RFC 3021' if mask == 31
   hosts = 2**(32-mask)
   hosts = 2 if mask == 31
   hosts = 1 if mask == 32
   res[:info] << _("Hosts/Net: %s" % hosts)
   res[:ips]  = info_ips
   res[:name] = "#{self.address}/#{self.mask}"
   res[:name] << ' --&gt; ' + self.gateway if route?
   res[:info] << _("Static route with gateway: %s" % self.gateway) if route?
   res
  end
  
  def nice_mask
    IPAddr.new("0.0.0.0/#{mask}").nice_mask
  end
  

  
  
 end

