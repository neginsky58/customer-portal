class CustomerAnnouncementCheck < ActiveRecord::Base
  belongs_to :user
  belongs_to :customer_announcement
  
  
  def self.create_for_user_and_announcement(user,customer_announcement)
    CustomerAnnouncementCheck.create(:user_id=> user.id , :customer_announcement_id => customer_announcement.id)
  end
end
