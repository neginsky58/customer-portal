
class Journal < ActiveRecord::Base
 
 self.table_name = 'journals'

 has_many   :transactions
 has_one   :invoice

 def before_save
    self.created = Time.now
 end

end
