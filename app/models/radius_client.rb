class RadiusClient < ActiveRecord::Base
  
  self.table_name = 'radius_clients'
  belongs_to :customer
  validates_uniqueness_of :nas_name
  validates_presence_of :nas_name
  validates_presence_of :secret
  
  def validate
    if self.portal_theme_id then
      t = PortalTheme.find(self.portal_theme_id) rescue false
      errors.add(:portal_theme_id, "Bad theme") unless t
      if t then
        errors.add(:portal_theme_id, "Bad theme owner") unless t.customer_id == self.customer_id
      end
    end
  end
end
