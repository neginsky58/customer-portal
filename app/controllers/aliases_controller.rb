
class AliasesController < ApplicationController


layout 'std'

before_filter :mk_location
before_filter :require_login
before_filter :check_settings, :except => [:invalid_setup, :change]
before_filter :verify_mail_id_with_customer
before_filter :check_permissions


 def check_permissions
   @session[:user].permission_to?('c,email,')
 end
 
def verify_mail_id_with_customer
 return if params[:id].nil?
 
 mail = Alias.find(params[:id])
 
 if mail.nil? then
   redirect_to :controller => 'sessions' 
   return false 
 end
 
 if mail.customer.id != @session[:user].customer.id then
    redirect_to :controller => 'sessions'
    return false
 end
end


def mk_location
   @location.add(_('Aliases'),  { :controller => 'aliases', :action => 'index' })
end


def check_settings
 if @session[:user].customer.customer_mail_settings.nil? ||
    @session[:user].customer.customer_mail_settings.max_aliases < 1 ||    
    @session[:user].customer.domains.size < 1 then
    redirect_to :action => 'invalid_setup'
    return false
 end
 
end

def invalid_setup 
 syslog "Invalid setup for mail (aliases) on customer %s" % @session[:user].customer.hid, "invalid_setup"
end


  def index
    @page_title = _("Your email accounts")
#    @paginate = Alias.paginate(:order => 'email_address', :page => params[:page], :per_page => 30,
#                           :conditions => "customer_id = %d" % @session[:user].customer_id )
    @aliases = Alias.find(:all, :conditions => ['customer_id=?', @session[:user].customer_id])
    @max_accounts = CustomerMailSettings.find_by_customer_id(@session[:user].customer).max_aliases
    @defined_accounts = @session[:user].customer.aliases.size
    @side_image = 'email-sign.jpg'
  end

  def show
  end

  def new
    @page_title = _("Add alias account")
    @location.add(_("Add"), {:controller => 'aliases', :action => 'new' })
    @alias = Alias.new
    @alias.customer = @session[:user].customer
    
  end
  
  def create
    @location.add(_("Add"), {:controller => 'aliases', :action => 'new' })
    @alias = Alias.new
    @alias.customer = @session[:user].customer  
  
    if request.method == 'POST' then
      @alias.attributes = params[:alias]
    #    puts @fmail.inspect
      if @alias.valid? then
        @alias.save
           
        clog "Added new alias '#{@alias.email_address}'", "email|add"
           
        flash[:notice] = _("New Alias account %s saved!" % @alias.email_address)
        redirect_to :controller => 'aliases', :action => 'index'
      else 
        render 'aliases/new'
      end
    end
  end

  def edit
    @location.add(_("Edit"), {:controller => 'aliases', :action => 'edit',:id=>params[:id].to_i })
    @alias = @session[:user].customer.aliases.find(params[:id])
  end
  
  def update
    @location.add(_("Edit"), {:controller => 'aliases', :action => 'edit',:id=>params[:id].to_i })
    @alias = @session[:user].customer.aliases.find(params[:id])
    @alias.attributes = params[:alias]
    if @alias.valid? then
      @alias.save
      clog "Added new alias '#{@alias.email_address}'", "email|add"
      flash[:notice] = _("New Alias account %s saved!" % @alias.email_address)
      redirect_to :controller => 'aliases', :action => 'index', :locale => params[:locale]
    else
      render 'aliases/edit'
    end
  end

  def destroy
    @alias = @session[:user].customer.aliases.find(params[:id])
    @alias.delete
    flash[:notice] = _("Alias has been removed")
    clog("Deleted Alias #{@alias.email_address}")
    redirect_to :controller => 'aliases', :action => 'index'
  end


end
