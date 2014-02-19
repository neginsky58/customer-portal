#require 'tmail'
#require 'mail2fs'
class TicketLog < ActiveRecord::Base
 #include Mail2Fs

  #set_table_name 'ticket_log'
  self.table_name = 'ticket_log'
  belongs_to :ticket
  belongs_to :user
#  has_many :ticket_correspondence
#  has_many :ticket_log_attachments

end
