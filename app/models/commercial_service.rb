# CommercialService links to a status and service
#
# Call from AR::Billable.commercial
#
class CommercialService < ActiveRecord::Base
  
  
  self.table_name = 'commercial_services'
  # no back_referencing possible
  
  belongs_to :service
##  belongs_to :commercial_status
##  

##  def status
##    commercial_status
##  end
##  
##  def status=(new_cs, log_message = '')
##    self.commercial_status=(new_cs)
##  end

end

