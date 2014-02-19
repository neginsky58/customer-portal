class TicketFeedback < ActiveRecord::Base
 
 self.table_name = 'ticket_feedback'
 belongs_to :ticket
end

