require 'ipaddr'

class IPAddr
  def get_mask
     _to_string(@mask_addr)
  end

  def default_route?
      @mask_attr == 0 && @addr == 0
  end
  
  def mask_bits
     ("%b" % @mask_addr).count('1')
  end
 
  def address_i
    @addr
  end
  
  def nice_mask
     _to_string(@mask_addr)
  end
   
end
