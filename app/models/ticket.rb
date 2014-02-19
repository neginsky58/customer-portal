class Ticket < ActiveRecord::Base
 belongs_to :customer
 belongs_to :circuit
 has_many :ticket_feedback
 belongs_to :resolver, :class_name => 'User',  :foreign_key => 'assigned_to'
 has_many :ticket_logs, :class_name => 'TicketLog'

  attr_accessor :type # determine the queue from this value!
  
  
  def self.get_mail_for(type)
    SITE_CONFIG[:ticket_queue_emails][type] rescue 'support@maxnet.ao'
  end
  
  def self.new_from_web(params)
    self.user = current_user
    self.message = formdata['message']
    self.log_message = 'Ticket created (via webinterface)'
    self.log_type = 'CORRESPONDENCE'
    self.action = ACTION_CREATE_FROM_WEB
  
  end
 
   # ticket token is just an identifier. Not necessarily unique.
  def token
    (self.created.to_i.modulo(100000) + self.id).to_s
  end
  
 
   # true if ticket is merged
  def merged?
    !!merge_ticket_id
  end

  def self.visible_for_customer(customer_id)
    Ticket.where(:customer_id=>customer_id.to_i)
  end


   def self.find_by_code(code)
    t = Ticket.find(:first,:conditions=>["code = ?",code])
    
    return nil unless t
    
    t.merged? ? t.merged_into : t
  end
  
    # returns ticket this ticket is merged into 
  def merged_into
    checked = []
    t = self
    while t.merged?
      t = Ticket.find(t.merge_ticket_id)
      raise "Merge loop: #{checked.inspect}" if checked.include?(t.id)
      checked << t.id
    end
    t
  end
  
  
  
  def self.priorities
    { 10 => 'VERY URGENT',
      9 => 'URGENT',
      8 => 'HIGH',
      5 => 'NORMAL',
      3 => 'RELAX',
      1 => 'IFTIME' }
  end
  
  
  def hpriority
    Ticket.priorities[self.priority]
  end

  def progress
     (status == 'RESOLVED') ? 100 : self.process_status
  end

  def subject
    if self.merge_ticket_id
      return _("Merged with %s") % Ticket.find(self.merge_ticket_id).code
    end
    self.read_attribute 'subject'
  end
    
end

