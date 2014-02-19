
class FeedbackController < ApplicationController
 layout 'std'

  before_filter :find_ticket, :only => [:show,:update]

  def find_ticket
    @ticket_code =  params[:id]
    @ticket_token = params[:ticket_token]

    @ticket = Ticket.find_by_code(@ticket_code)
    puts @ticket.token
    if !@ticket then
#      @areason = "Not in database"
      render :action => :ticket_not_found and return
    end

    if @ticket.token != @ticket_token then
#      @areason = "Invalid Token"
      render :action => :ticket_not_found and return
    end

    
    if @ticket.status != 'RESOLVED' then
      @areason = "Not RESOLVED"
      render :action => :ticket_not_found and return
    end
    
    if @ticket.ticket_feedback.size > 0 then
      render :action => :ticket_already_done and return
    end
    

  end
  
  def index
    render :text=>'nothing to see here'
  end
  
  def show
    render 'ticket'
  end
  
  def update
    fb = TicketFeedback.new
    fb.ticket = @ticket
    fb.feedback_data = ticket_result_to_human(params)
    fb.score = ticket_score_by_result(params)
    fb.created = Time.now
    fb.request_contact = !!params['request_contact_of_supervisor']
    fb.save!
    render :action => 'ticket_submit_thanks'
  end
  
  def rate_to_human(score)
    case (score.to_i)
      when 0: 'very-bad'
      when 1: 'bad'
      when 2: 'neutral'
      when 3: 'good'
      when 4: 'very-good'      
    end
  end

  def ticket_result_to_human(params)
    [].tap do |result|
       params.find_all { |k,v| k =~ /^rate_/ }.each do |rate|
           result << "#{rate[0]} == #{rate_to_human(rate[1])}"
       end
       result << "Contact: #{params['your_name']}"
       result << "Comment:\n   "+params['comment'].split(/\n/).join("\n   ")
       result << "Request Call: "+(params['request_contact_of_supervisor'] ? 'YES' : 'no')
       result << ''
       result << "Score Rating: #{ticket_score_by_result(params).to_s}%"

    end.join("\n")    
  end
  
  def ticket_score_by_result(params)
      result = 0
      nresult = 0
      params.find_all { |k,v| k =~ /^rate_/ }.each do |rate|
           nresult+=1
           result+=rate[1].to_i
      end
      
      ((result.to_f / (nresult * 4)) * 100).to_i      
  end
  

#  def ticket_submit
#    fb = TicketFeedback.new
#    fb.ticket = @ticket
#    fb.feedback_data = ticket_result_to_human(params)
#    fb.score = ticket_score_by_result(params)
#    fb.created = Time.now
#    fb.request_contact = !!params['request_contact_of_supervisor']
#    fb.save!
#    render :action => 'ticket_submit_thanks'
#  end

  def ticket
  end
  

end

