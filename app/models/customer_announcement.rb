class CustomerAnnouncement < ActiveRecord::Base
  has_many :customer_announcement_checks
  validates_length_of :subject, :within => 2..200
  
  def self.find_for_user(user)
    # we only show announcements with age < 6 month
    exclude_ids = CustomerAnnouncementCheck.find(:all,:conditions=>["created_at > ? AND user_id = ?",(Time.now-6.month),user.id]).collect{|x|x.customer_announcement_id}
    
    
    all = exclude_ids.empty? ?
       CustomerAnnouncement.find(:all,:conditions=>["valid_from <= ? AND valid_to >= ?",Time.now,Time.now],:order=>'created_at DESC') :
       CustomerAnnouncement.find(:all,:conditions=>["valid_from <= ? AND valid_to >= ? AND id NOT IN (?) ",Time.now,Time.now,exclude_ids],:order=>'created_at DESC')
    # remove if not targeted at the user
    service_types = user.customer.billable_services.collect{|x|x.class.to_s}.uniq
    service_strings = user.customer.billable_services.collect{|x|x.service.to_s rescue nil}.uniq
    output = []
    all.each do |announcement|
      output << announcement if announcement.object_type.to_s == '' # collect if empty
      if service_types.include? announcement.object_type.to_s # user has this service!
        output << announcement if announcement.object_idstring.to_s == '' # collect if empty
        unless announcement.object_idstring.to_s == '' 
          valid_circuits = announcement.object_idstring.split(',').uniq
          output << announcement  if (valid_circuits - service_strings).size < valid_circuits.size # user should get the announcement
        end
      end
    end
    output
  end
  
  
  
  def self.find_first_for_user(user)
    find_for_user(user).last
  end
  
end
