
class CustomerAnnouncementsController < ApplicationController
layout 'std'
  def index
    user_id = session[:user].to_i
    @fuser = User.find(user_id)
    @announcement = CustomerAnnouncement.find_first_for_user(@fuser)
    if @announcement.nil?
      redirect_to '/'
      return    
    end
    @announcements = [@announcement]
    render #:layout=> false
  end
  
  # WARNING.. this is not by the book
  # adds a view block for the specific user
  # additionaly I could not get js to work
  def destroy
    ca = CustomerAnnouncement.find(params[:id])
    @fuser = User.find(session[:user].to_i)
    CustomerAnnouncementCheck.create_for_user_and_announcement(@fuser,ca)
    redirect_to customer_announcements_path
  end

end
