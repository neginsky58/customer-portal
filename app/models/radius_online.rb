class RadiusOnline < ActiveRecord::Base

self.table_name = 'radius_online'
set_primary_key :acct_session_id
belongs_to :dial_profile
end
