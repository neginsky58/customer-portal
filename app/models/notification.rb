class Notification < ActionMailer::Base
  def new_mail(mail)
    @subject    = _("New email is ready")
    @body       = { :user => mail }
    @recipients = mail.email_address
#    @recipients = 'martin@internet.ao'
    @from       = 'MAXNET <support@maxnet.ao>'
    @sent_on    = Time.now
    @headers    = {}
  end

                                         
  def tech_request(params)
    @subject = params[:subject]
    @body = { :params => params }
    @recipients = 'support@maxnet.ao'
    @from     = params[:requestor]
    @sent_on  = Time.now
    headers = {}
  end


                                         
  def create_ticket(params)
    @subject = params[:subject]+ ' '+ "[[[[customer_id:#{params[:customer_id]}|circuit_id:#{params[:circuit_id]}|priority:#{params[:priority]}]]]]"
    @body = { :params => params }
    @recipients = params[:recipient]
    @from     = params[:requestor]
    @sent_on  = Time.now
    headers = {}
  end

end
