
class EmailController < ApplicationController
layout 'std'

before_filter :mk_location, :except => :change
before_filter :require_login, :except => :change
before_filter :require_email_login, :only => :change
before_filter :check_settings, :except => [:invalid_setup, :change]
before_filter :verify_mail_id_with_customer
before_filter :check_permissions


 def check_permissions
   return false unless @session[:user]
   @session[:user].permission_to?('c,email,')
 end
 
def verify_mail_id_with_customer
 return if params[:id].nil?
 
 mail = MyMail.find(params[:id])
 
 # normal login:
 if @session[:user]
   if mail.nil? then
     redirect_to :controller => 'sessions' 
     return false 
   end
   
   if mail.customer.id != @session[:user].customer.id then
      redirect_to :controller => 'sessions'
      return false
   end
  else # login via mail address
    unless @session[:email] == mail
      redirect_to :controller => 'sessions'
      return false
    end
  end

end


def mk_location
   @location.add(_('Email'),  { :controller => 'email', :action => 'index' })
end


def check_settings

 if @session[:user].customer.customer_mail_settings.nil? || @session[:user].customer.customer_mail_settings.max_accounts < 1

    redirect_to :action => 'invalid_setup'
    #return false

 end
 
end

def invalid_setup 
 syslog "Invalid setup for mail on customer %s" % @session[:user].customer.hid, "invalid_setup"
end

  private
  def get_message_status(user, pass)
    require 'net/pop'
    begin 
      pop = Net::POP3.new(POP3_SERVER)
      pop.start(user, pass)             # (1)
      inbox = pop.mails.size
      pop.finish
    rescue  => e
      inbox = "(" + _("Not available") + ")"
      begin
        pop.finish
      rescue => e
      rescue Timeout::Error => e # not a subclass of Stderr.. so need to be rescued explicitly..
      end
    rescue Timeout::Error => e # not a subclass of Stderr.. so need to be rescued explicitly..
      inbox = "(" + _("Not available") + ")"
      begin
        pop.finish
      rescue => e
      rescue Timeout::Error => e # not a subclass of Stderr.. so need to be rescued explicitly..
      end
    end
   inbox
  end

public


def delete
 @mail = MyMail.find_by_id_and_customer_id params[:id], @session[:user].customer.id
 redirect_to 'index' if @mail.nil?
 
 if request.method == 'POST' then
   clog "Deleted mail '#{@mail.email_address}'", "email|delete"
   flash[:notice] = _("Email %s deleted!" % @mail.email_address)
   @mail.destroy
   redirect_to :action => 'index'
 end
 
 @location.add(@mail.email_address, { :action => 'view', :id => @mail.id })
 @location.add(_("Delete"), {:action => 'delete', :id=> @mail.id })

 
 @page_title = _("Delete %s" % @mail.email_address)

 @inbox = get_message_status @mail.email_address, @mail.password_clear

end

def view
 @mail = MyMail.find_by_id_and_customer_id params[:id], @session[:user].customer.id
 redirect_to 'index' if @mail.nil?
 
 @location.add(@mail.email_address, { :id => @mail.id })
 @page_title = _("Email %s" % @mail.email_address)
 
 require 'net/pop'
 
 @inbox = get_message_status @mail.email_address, @mail.password_clear
 
end


def index
 @page_title = _("Your email accounts")

 @emails = MyMail.find(:all, :conditions => ['customer_id=?', @session[:user].customer_id] )
 
 @max_accounts = @session[:user].customer.customer_mail_settings.max_accounts
 @defined_accounts = @session[:user].customer.mail.find(:all).size
 @side_image = 'email-sign.jpg'
end

def add
 @page_title = _("Add email account")
 @location.add(_("Add"), {:controller => 'email', :action => 'add' })
 @fmail = MyMail.new
 @fmail.customer = @session[:user].customer
 if request.method == 'POST' then
    @fmail.attributes = params[:fmail]
#    puts @fmail.inspect
    if @fmail.valid? then
       @fmail.save
       Notification.deliver_new_mail(@fmail)
       
       clog "Added new email '#{@fmail.email_address}'", "email|add"
       
       flash[:notice] = _("New Email account %s saved!" % @fmail.email_address)
       redirect_to :controller => 'email', :action => 'index'
    end
 end
end

# this only works for one email (email -login)
def change
  @location.add(@email.email_address)
  @page_title = _("Your email %s" % @email.email_address)
#  @fmail = @email.dup 
# fmail.new_record would always be true!
  @fmail = @email
  @no_delete_button = true
  @admin_options = false
  @post_to = 'change'
  online_help 'test'
  
  if request.method == 'POST' then
    @newmail = @fmail
    p = params[:fmail].dup.delete_if do |k,v| 
        %w{max_msgsize email_address antivirus_enable password password_confirmation}.include?(k) 
    end
    @newmail.attributes = p
    
    # write password only if it is entered
    if (!params[:fmail]['password'].strip.empty?) then
          @newmail.password = params[:fmail]['password']
          @newmail.password_confirmation = params[:fmail]['password_confirmation']
    end
    
    @newmail.email_address = @fmail.email_address
    if @newmail.valid? then
      if !@newmail.changes.empty? then
        @newmail.save 
        clog "Email updated: '#{@fmail.email_address}'", "email|edit"
        flash[:notice] = _("Email updated")
      else
        flash[:notice] = _("Nothing changed")
      end
    else
        flash[:notice] = nil    
    end
  end
  
  
  @fmail.password = ""   # hide passwords
  @fmail.password_confirmation = ""
    
  render :template => 'email/edit'
end


def edit
  @fmail = MyMail.find_by_id_and_customer_id params[:id], @session[:user].customer_id
  redirect_to :controller => 'sessions', :action => 'logout' if @fmail.nil?
  
  @location.add(@fmail.email_address)
  @location.add(_("Edit"), {:action => 'edit', :id=> @fmail.id })
  @admin_options = true		# show admin options in _form_email.html.erb
  
  @page_title = _("Edit email %s" % @fmail.email_address)

  if request.method == 'POST' then
    @newmail = @fmail
    @newmail.attributes = params[:fmail]
    if (params[:fmail]['password'].strip == "") then
          @newmail.password = @fmail.password_clear
          @newmail.password_confirmation = @fmail.password_clear
    end
    
    @newmail.email_address = @fmail.email_address
    if @newmail.valid? then
      @newmail.save
      clog "Email updated: '#{@fmail.email_address}'", "email|edit"
      flash[:notice] = _("Email updated")
      redirect_to :action => 'index'
    end
  end

  @fmail.password = ""   # hide passwords
  @fmail.password_confirmation = ""
  
  require 'net/pop'
 
  @inbox = get_message_status @fmail.email_address, @fmail.password_clear
end


def settings
 @page_title = _("Your email settings")
 @location.add(_("Settings"), {:controller => 'email', :action => 'settings' })
end


end
