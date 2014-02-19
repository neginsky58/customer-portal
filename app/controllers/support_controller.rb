
class SupportController < ApplicationController
layout 'std'

before_filter :mk_location
before_filter :require_login
before_filter :validate_contact_id_with_session, :only => [:contact_edit, :contact_delete]
before_filter :check_features


def check_features
  render :template => 'support/no_features.html.erb' and return false unless @features[:support]
end


def validate_contact_id_with_session
  if !params[:id].nil? then
    c = Contact.find params[:id]
    if c.nil? || (c.customers[0].id.to_i != @session[:user].customer.id) then
       redirect_to :action=> 'index'
       return false
    end
  end
end


def mk_location
  @location.add(_('Support'),  { :controller => 'support', :action => 'index' })
end

def contact_add
 @page_title = _("Add a new contact")
 @location.add(_("Contacts"), { :controller => 'support', :action => 'index' })
 @location.add(_("Add"), { :controller => 'support', :action => 'contact_add' })
 
 @fcontact = Contact.new

 if request.method == 'POST' then
   @fcontact.attributes = params[:fcontact]
   @fcontact.private = false
   if @fcontact.valid? then
     Contact.transaction do 
       @fcontact.save
       clog("Added Contact #{@fcontact.hname}", 'support')
       @session[:user].customer.contacts << @fcontact
     end
     flash[:notice] = _('Contact saved!')
     redirect_to :action => 'index'
   end
 end
end

def contact_edit
  @page_title = _("Edit contact")
  @location.add(_("Contacts"), { :controller => 'support', :action => 'index' })
  
  @fcontact = Contact.find(params[:id])
  raise ArgumentError, 'Owner mismatch' unless @session[:user].customer.contacts.include?(@fcontact)
  raise ArgumentError, "Contact is private" if @fcontact.private
 
  @location.add(@fcontact.firstname+" "+@fcontact.lastname, 
       { :controller => 'support', :action => 'contact_edit', :id => @fcontact.id })
  
  if request.method == 'POST' then
    @fcontact.attributes = params[:fcontact]
    if @fcontact.valid? then
      @fcontact.save
      flash[:notice] = _('Contact updated')
      redirect_to :action => 'index'
    end
  end
end


def contact_delete
 @fcontact = Contact.find params[:id]
 raise ArgumentError, 'Owner mismatch' unless @session[:user].customer.contacts.include?(@fcontact)
 raise ArgumentError, "Contact is private" if @fcontact.private

 Contact.transaction do 
   clog("Delete Contact #{@fcontact.firstname} #{@fcontact.lastname}", 'support')
   @fcontact.destroy
 end
 flash[:notice] = _("Contact Deleted")
# reload_session
 redirect_to :action => 'index'
end



def index
 @page_title = _("%s Customer Support" % get_company_name)
 @contacts = @session[:user].customer.contacts.delete_if { |c| c.private }.sort { |a,b| a.lastname <=> b.lastname  }
 @side_image = 'support.jpg'
end

def technical
raise 'depreciated'
 @location.add(_("New technical request"), { :controller => 'support', :action => 'technical' })
 @page_title = _("Technical Support")
 @errors = []
 
 if request.method == 'POST' then
  if params[:subject].length < 2 then
    @errors << _("Specify a subject")
  end
  if params[:request].length < 10 then
    @errors << _("Type a details request")
  end

  requestor, contact_id = params[:contact].split(',')
  contact = Contact.find(contact_id.to_i)

  @errors << "invalid contact" unless contact
  
  if @errors.empty? then
    Notification.deliver_tech_request(
       :customer => @session[:user].customer,
       :site => params[:site],
       :subject => params[:subject],
       :request => params[:request],
       :requestor => requestor,
       :type => params[:type],
       :contact => contact)

    @requestor = requestor
    @subject = params[:subject]

    render :template => 'support/technical_sent'
    # send mail
    # mail will create ticket...?
  end
 end
end


def sales
 @page_title = _("Sales/Commercial contact")
 
end



end
