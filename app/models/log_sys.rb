class LogSys < ActiveRecord::Base

self.table_name = 'log_sys'
belongs_to :user

end
