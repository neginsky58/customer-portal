class Transaction < ActiveRecord::Base
 
 self.table_name = 'trans'
 belongs_to :journal
 belongs_to :account


end
