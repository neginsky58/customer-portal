class Domain < ActiveRecord::Base

self.table_name = 'dns_domain'
has_many :customer_domains
has_many :customers, :through => :customer_domains
end
