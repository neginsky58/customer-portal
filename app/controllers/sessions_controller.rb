
class SessionsController < ApplicationController
 layout 'std'
 
 before_filter :mk_location

# I'll filter manually for 'index' so the ugly error message disapperars
 before_filter :require_login, :only => ['password', 'logout', 'index']
  
  def mk_location
    syslog "DEBUG 6: mk_location"
    syslog @session[:user]
    if @session.nil? || @session[:user].nil? then
       @location.add(_('Session'),  { :controller => 'sessions', :action => 'login',:reseller => @reseller})
    else 
      @location.add(_("User '%s'" % @session[:user].username), { :controller => 'sessions', :action => 'index' })
    end
  end

 
   def welcome
   end


  def login
    @location.add(_("%s Login" % get_portal_name),  { :controller => 'sessions', :action => 'login',:reseller => @reseller })
    @side_image = 'wormhole.jpg'
    @page_title = _("Login")
    online_help "session-login"

    # respond_to do |format|
    #   format.html
    #   format.json
    # end

    if request.method == 'POST' then      
      c = User.get_by_login(params[:username], params[:passwd])

      if c.nil? then
          flash[:notice] = _("Wrong username or password")

          syslog("Wrong login: '%s'" % [params[:username]],
                  "login") unless params[:username] == ""
    #          sleep 2 # this is not helping...!
      elsif c.customer.nil? then
          flash[:notice] = _("Customer logins only")
      else 
        session[:user] = c.id
        session[:session] = { :login_time => Time.now, 
                               :ip_addr => request.remote_ip }
         
        reload_session
        clog "Logged in", "session::login"
        flash[:notice] = ""
       
       #redirect_to :action => 'index',:reseller=>@reseller
       syslog "DEBUG 5:"
       syslog @session[:user]

       redirect_to :action => 'index',:reseller=>@reseller
       
      end
    end
  end
 
 def login_email
   @location.add(_('Email Login'),  { :controller => 'sessions', :action => 'login_email',:reseller => @reseller})
   online_help 'session-login'
   @side_image = 'email-sign.jpg'
   
   if request.method == 'POST' then      
      c = MyMail.get_by_login(params[:email], params[:passwd])
      if c.nil? then
          flash[:notice] = _("Wrong username or password")
          syslog("Wrong email login for '%s'" % [params[:email]],
                  "login") unless params[:email] == ""
      else 
       session[:email] = c.id
       session[:session] = { :login_time => Time.now, 
                             :ip_addr => request.remote_ip }
       
       session[:user] = nil
       flash[:notice] = ""
       redirect_to :controller => 'email', :action => 'change',:reseller=>@reseller
       
      end
   end
   
 end
 
 def logout
  @page_title = _("Logged out")
  clog "Log out", "session::logout"
  @session[:user] = nil
  reset_session
  syslog "Logged out"
 end
 
 def password
  @page_title = _("Change password")
  @location.add(_('Change password'),  { :controller => 'sessions', :action => 'password' })
  @fuser = User.find @session[:user].id
  
  if request.method == 'POST' then
     @fuser.password = params[:fuser][:password]
     @fuser.password_confirmation = params[:fuser][:password_confirmation]
     
     if @fuser.valid? then
       @fuser.save
       flash[:notice] = _("Password saved! Use new password on next login!")
       
       clog "Changed password", "session::password"
       redirect_to :action => 'index'
     end
  end
  @fuser.password  = "" # don't show passwords
  @fuser.password_confirmation = ""
end
 
  def index
    
    user_id = @session[:user].id.to_i
    @fuser = User.find(user_id)
    @announcements = CustomerAnnouncement.find_for_user(@fuser)
    if @announcements.size > 0
      redirect_to customer_announcements_path
      return    
    end
    online_help 'session-index'
    @page_title = _("Welcome")
    @page_title = _("User '%s'" % @session[:user].username)
  end
end
