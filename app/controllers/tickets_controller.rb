
class TicketsController < ApplicationController
  layout 'std'

  before_filter :mk_location
  before_filter :require_login
  before_filter :check_features
  before_filter :mk_submenu#, :except => 'index'



  def mk_submenu
    return unless @features[:support]
    @submenu = []    
    @submenu << { :title => _('Show all Tickets').capitalize,:url => tickets_path, :active => (params[:only].nil? and params[:action]=='index') }
    @submenu << { :title => _('Show only open Tickets').capitalize,:url => tickets_path(:only=>'open'), :active => (params[:only]=='open') }
    @submenu << { :title => _('Show only resolved Tickets').capitalize,:url => tickets_path(:only=>'resolved'), :active => (params[:only]=='resolved') }
  end



  def index
   @page_title = _("%s Tickets" % get_company_name)
  #@side_image = 'support.jpg'
    @tickets = Ticket.visible_for_customer(@session[:user].customer.id)
    if params[:only] == 'open'
      @tickets = @tickets.where(["status IN (?)",['NEW','OPEN']])
    elsif params[:only] == 'resolved'
      @tickets = @tickets.where(["status IN (?)",['RESOLVED','CLOSED']])
    end
    @tickets = @tickets.where(["status != ?","REJECTED"]).order("created DESC").all
  end

  def show
    @ticket = Ticket.visible_for_customer(@session[:user].customer.id).find(params[:id])
  end

  def new
    @ticket = Ticket.new
    @location.add(_("New technical request"), new_ticket_path)
    @page_title = _("Technical Support")

  end
  
  def create
    @ticket = Ticket.new(params[:ticket])

  
    @errors = []
 
    requestor, contact_id = params[:contact].split(',')
    contact = Contact.find(contact_id.to_i)
    @errors << "invalid contact" unless contact
    @errors << "subject too short" unless params[:ticket][:subject].size > 2
  
    recipient = Ticket.get_mail_for(params[:type]) rescue 'support@maxnet.ao'
  
    if @errors.empty? 
    Notification.deliver_create_ticket({
       :customer_id => @session[:user].customer.id,
       :circuit_id => params[:ticket][:circuit_id],
       :priority => params[:ticket][:priority],
       :subject => params[:ticket][:subject],
       :request => params[:content],
       :requestor => requestor,
       :contact => contact,
       :recipient => recipient
       })

      @requestor = requestor
      @subject = params[:ticket][:subject]
      render :template => 'support/technical_sent'
      return
    else
      render 'new'
    end
  
  end



  private
  
  def check_features
    render :template => 'support/no_features.html.erb' and return false unless @features[:support]
  end


  def mk_location
    @location.add(_('Support'),  { :controller => 'support', :action => 'index' })
  end





end
