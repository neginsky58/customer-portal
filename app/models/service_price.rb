class ServicePrice < ActiveRecord::Base
  belongs_to :service
  belongs_to :customer

  def get_record
     service.get_record(self.record_id)
  end
  
  def self.set_for_iservice(iservice, price,volume=0)
    raise "No Commercial Service" unless iservice.commercial.service
    sp = ServicePrice.find(:first, 
           :conditions => ['service_id = ? and record_id = ?',
                            iservice.commercial.service.id, iservice.record_id])
    if !sp then
       sp = ServicePrice.create do |s|
          s.service_id = iservice.commercial.service.id
          s.record_id  = iservice.record_id
       end
    end
    sp.price = price
    sp.volume = volume.to_i
    sp.save!
  end
  
end

