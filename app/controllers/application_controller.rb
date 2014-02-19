
class ApplicationController < ActionController::Base
  #protect_from_forgery
  
  
#  before_filter :redefine_paths
#  def redefine_paths
#   ActionController::Base.view_paths = "app/views_maxnet"
#end

  
  
before_filter :set_gettext_locale
before_filter :check_session
before_filter :create_location

#before_filter :set_language # deprecated
before_filter :init_document_ready_js
before_filter :set_reseller

def set_reseller
  @reseller = ''
  # try to get agent from session
  @agent = User.find(session[:user]).customer.agent rescue nil
  # otherwise try to get agent from reseller request parameter
  @agent = Agent.where(:hid=>params[:reseller].to_s).first unless @agent  
  # otherwise try to get agent from domain -> customer association
  unless @agent then
    domain = Domain.find_by_domain_name(request.host) rescue nil
    customer = domain.customers.first if domain
    if customer and not @agent    
      @agent = Agent.where(:hid=>customer.hid.to_s).first rescue nil
    end
  end
  @reseller = @agent.hid if @agent  
end

def init_document_ready_js
  @js = []
end


def online_help(help_id)
 help =  # Locale.translate_bulk(help_id, params[:locale]) FIXME
 @online_help = help
end


def check_session
 @session ||= {}
end


  helper_method :get_company_name
  def get_company_name
    r = SITE_CONFIG[:company_name]
    if @agent
      r = CGI::escapeHTML(@agent.name)
    elsif params.include? :reseller and agent = Agent.find_by_hid(params[:reseller])
      r = CGI::escapeHTML(agent.name)
    end
    r
  end
  
  helper_method :get_portal_name
  def get_portal_name
    portal_name = SITE_CONFIG[:portal_name]
    if @agent
       portal_name = _('My')+' '+CGI::escapeHTML(@agent.name)
    elsif params.include? :reseller and agent = Agent.find_by_hid(params[:reseller])
       portal_name = _('My')+' '+CGI::escapeHTML(agent.name)
    end
    portal_name
  end









# deprecitated
###def set_language
####FastGettext.add_text_domain 'pt'
###   mo_path = Rails.root.to_s + "/mo"
###   puts "Mo path is #{mo_path}"
###   GetText.bindtextdomain(TEXT_DOMAIN, :path => mo_path)
###   set_to = DEFAULT_LOCALE
###   if params[:locale] then
###     set_to = params[:locale]
###   end
###   
###   puts "setting locale to: #{set_to}"
###   GetText.locale = set_to
###   
####   raise _("Login")

####   if !params[:locale].nil? && Locale.languages.include?(params[:locale])
####      Locale.set params[:locale]
####   else
####      redirect_to params.merge( 'locale' => Locale.base_language )
####   end
###end

def create_location
  @location = Location.new
end

def setup_features(agent)
  @features = {}
  f = agent.features.split(',').map { |e| e.strip.downcase }
  @features[:circuit_info] =     f.include?('my_circuit_info')
  @features[:support]      =     f.include?('my_support')
  @features[:email_alias]  =     f.include?('my_email_alias')
  @features[:email_autoreply]  = f.include?('my_email_autoreply')
end

 def default_url_options(options={})
    { :locale => I18n.locale == I18n.default_locale ? nil : I18n.locale  }
  end


def require_login
  if session[:user].nil? then
#   flash[:error] = "You need to login to access this page".t
   redirect_to :controller=> 'sessions', :action => 'login' and return false
  end
  
  @session ||= {}
  @session[:user] = User.find(session[:user])
  @agent = @session[:user].customer.agent
  setup_features(@agent)
end

def require_email_login
  redirect_to :controller => 'sessions',:action => 'login' if session[:email].nil?
  @email = MyMail.find(session[:email].to_i)
  redirect_to :controller => 'sessions',:action => 'login' unless @email  
  @session ||= {}
  @session[:email] = @email
  setup_features @email.customer.agent
end



def reload_session
 @session[:user] = User.find session[:user]
end


# systemlog
def syslog(message, id_string="")
 log = LogSys.new
 log.message = message
 log.id_string = "[mymax] " + id_string
 log.ip_number = request.env['REMOTE_ADDR']
 log.user_id = @session[:user].id unless @session[:user].nil?
 log.created = Time.now
# puts request.inspect
 log.save
end

# customer-log
def clog(message, id_string ="")
 if @session[:email] then
   log = LogCustomer.new
   log.message = message
   log.id_string = "[mymax-email] " + id_string
   log.ip_number = request.env['REMOTE_ADDR']
   log.customer_id = @session[:email].customer.id
   log.created = Time.now
   return log.save
 end
 
 return false unless @session[:user]
 
 log = LogCustomer.new
 log.message = message
 log.id_string = "[mymax] " + id_string
 log.ip_number = request.env['REMOTE_ADDR']
 log.user_id = @session[:user].id
 log.customer_id = @session[:user].customer.id
 log.created = Time.now
 log.save
end
  
  def assert(condition)
    raise "Assertion Failed" unless condition
  end
  
  
  
end
