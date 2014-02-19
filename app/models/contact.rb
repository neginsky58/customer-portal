class Contact < ActiveRecord::Base

self.table_name = 'contact'

validates_length_of :lastname, :within => 2..128, :message => _("Enter your last name")

has_many :customer_contacts
has_many :customers, :through => :customer_contacts
# has_and_belongs_to_many :customers, :join_table => 'customer_contact'

# manually destroy customer relation to this record
before_destroy do |record| 
  c = CustomerContact.find_by_contact_id(record.id)
  c.destroy if !c.nil?
end

def hname
 "#{firstname} #{lastname}"
end

end
