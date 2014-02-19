# gets generated/updated by CircuitTraffic in case the current commercial service is a payg volume service
# the counter needs either to be resetted or deleted by hand!
# it counts traffic even if the link status is not active! is this ok?!
class CircuitPayg < ActiveRecord::Base
  belongs_to :circuit
  belongs_to :customer
  belongs_to :commercial_service
  
  def total_usage
    self.counter_up.to_i+self.counter_down.to_i # todo fix unit!
  end
  
  def download
    self.counter_down.to_i 
  end
  
  def upload
    self.counter_up.to_i 
  end
  
  def volume
    self.circuit.volume.to_i * 1024 * 1024 # user enters in MB!
  end
  
  def remaining_usage
    (self.volume - self.total_usage)
  end
  
  def price
    self.circuit.price
  end
 
  
  def balance # returns false in case of volume == 0
    (self.price * self.remaining_usage / self.volume ) rescue false
  end
  
  def self.find_or_create_by_circuit(circuit)
    unless cp = circuit.reload.circuit_payg
      cp = CircuitPayg.create(:circuit=>circuit,:customer_id=>circuit.customer_id,:commercial_service_id=>circuit.commercial_service_id)
    end
    raise 'I should have found or created a CircuitPayg' unless cp
    cp
  end
  
  def update_traffic(diff_in,diff_out)
    self.counter_up = self.counter_up.to_i + diff_out.to_i
    self.counter_down = self.counter_down.to_i + diff_in.to_i
    self.save
  end

end
