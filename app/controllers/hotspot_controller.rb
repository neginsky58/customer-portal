
class HotspotController < ApplicationController
 layout 'std'
 
 before_filter :mk_location, :except => :ticket_status
 before_filter :require_login, :except => :ticket_status
 before_filter :check_permissions, :except => :ticket_status
 

 def ticket_status
   response.headers['Access-Control-Allow-Origin'] = '*'
   response.headers["Cache-Control"] = "no-cache, no-store, must-revalidate"
   response.headers["Pragma"] = "no-cache"
   response.headers["Expires"] = "0"
   
   user = params['user']
   pass = params['pass']

   if (!user || !pass) then
     render :text => 'Bad Call', :status => 400 and return
   end
   
   profile = DialProfile.where('username = ?', user).first
   if (!profile) then 
     render :text => "Bad Call 2", :status => 403 and return
   end
   
   if Digest::MD5.hexdigest(profile.password) != pass then
     render :text => "Bad Call 3", :status => 403 and return 
   end
   
   
   result = { 'username' => profile.username,
                     'status'   => profile.status,
                     'data_credit' => profile.data_credit,
                     'dial_type'  => profile.dial_type,
                     'created'   => profile.created,
                     'valid_until' => profile.valid_until,
                     'time_credit' => profile.time_credit,
                     'time_used' => profile.time_used,
                     'time_last' => profile.time_last }
   
   result['valid_until_s'] = (Time.now - profile.valid_until).to_i if profile.valid_until

   render :json => { :dial_profile => result}.to_json, :status => 200
 end

 def check_permissions
   @session[:user].permission_to?('c,hotspot,')
 end
 
 def mk_location
   @location.add(_('Hotspot'),  { :controller => 'hotspot', :action => 'index' })
end

 
 def index
  @page_title = _("Hotspot")
  @side_image = SITE_CONFIG[:hotspot_image]
  
  @account  = @session[:user].customer.main_account
  
  @buy_link = @session[:user].permission_to?('c,hotspot,w')
  
  #@dial_profiles = @session[:user].customer.dial_profiles.find_all { |p| p.status == 'A' }.sort_by { |p| p.created.to_i * (-1)}
  
  
  params[:size] ||= 20
  params[:status] = 'A'

  @dial_profiles = @session[:user].customer.paginated_object_find(DialProfile,
                                                  params,
                                   {
             :select => "dial_profiles.* ,
                        (SELECT CASE dial_type WHEN 'TIME' THEN CAST(valid_until AS text) 
                          WHEN 'RELTIME' THEN CAST(time_credit AS text) 
                          WHEN 'VOLUME' THEN CAST(data_credit AS text) END) AS calculatedcredit",
             :include=>[:radius_online],
             :sortfields=> ['dial_profiles.username', 'dial_profiles.created', 
                            'dial_profiles.online', 'radius_online.acct_session_id', 'calculatedcredit'],
             :searchfields=>['dial_profiles.username'],
             :searchfields_integer=>[],
             :default_sort=>"dial_profiles.created DESC" }, params[:size].to_i.abs)

  
  
  render 'index',:layout=>'std'
 end
 
 def view
    @page_title = _("View Hotspot Account")
    @dp = DialProfile.find(:first, :conditions => ['status = ? AND username = ?', 'A', params['user']] )
    
    assert @dp
    assert @dp.customer == @session[:user].customer       
    
    @acct = DialProfile.connection.execute("SELECT * from radius_acct 
                                            WHERE dial_profile_id = #{@dp.id} 
                                               AND status != 'Alive' 
                                               ORDER by event_time").to_a
                                               

    if (@acct.empty? && @dp.created >= 2.hours.ago && !@dp.online?) then
       @can_cancel = true
    end
 end
 
 def cancel
   view
   assert @can_cancel
   User.transaction do
     @dp.destroy
     clog("Cancelling Hotspot user: #{@dp.username}")
   end
   flash[:notice] = _("Account '%s' cancelled" % @dp.username)
   redirect_to :action => 'index'
 end


 def account
    @page_title = _("Account statement")
    assert @session[:user].permission_to?('c,hotspot,w')
 end

 def buy
   assert @session[:user].permission_to?('c,hotspot,w')
   
   if request.method == 'POST' && !session[:hotspot_buy_block] then
      
      @errors = ''
      
      begin
        @tariff = DialTariff.find(params[:tariff_id].to_i) 
      rescue 
        @errors << "Select a Tariff ".t
      end
  
      user_balance = @session[:user].customer.main_account.balance
      total_price = 0
      total_price = @tariff.price if @tariff

      # a negative user balance indicates that the user _has_ money!
      user_balance = -1 * user_balance # make it sane for non accountants :)
      @errors << _("You don't have enough credit for this transaction. ") if user_balance < total_price

  
     
      if @errors.empty? then
        assert @tariff.customer_id = @session[:user].customer.id
        @dp = @tariff.buy!(:username => params[:username], :comment => params[:comment],:customer_id=>@session[:user].customer.id)
        session[:hotspot_buy_block] = true
        render :template => 'hotspot/buy_done' and return
      end
   end
 
  
   @page_title = _("Buy Hotspot Internet")
   
   @tariffs = @session[:user].customer.dial_tariffs
   if !session[:hotspot_buy_block] then
 
     @tariff_id = params[:tariff_id]
     @username = params[:username]
     @comment = params[:comment]
   end

   session[:hotspot_buy_block] = false

 end

 
 def buy_batch
   assert @session[:user].permission_to?('c,hotspot,w')
   
   if request.method == 'POST' && !session[:hotspot_buy_block] then
      
      @errors = ''
      
      begin
        @tariff = DialTariff.find(params[:tariff_id].to_i) 
      rescue 
        @errors << "Select a Tariff".t
      end
      
      @errors << _("I need to know how many passwords you want. ") if params[:batch_size].to_i <= 0
      @errors << _("I can only create maximal 20 passwords at once. ") if params[:batch_size].to_i > 20
  
      user_balance = @session[:user].customer.main_account.balance
      total_price = 0
      total_price = params[:batch_size].to_i * @tariff.price if @tariff

      # a negative user balance indicates that the user _has_ money!
      user_balance = -1 * user_balance # make it sane for non accountants :)
      @errors << _("You don't have enough credit for this transaction. ") if user_balance < total_price

     
      if @errors.empty? then
        assert @tariff.customer_id = @session[:user].customer.id
        @all_credentials = []
        1.upto(params[:batch_size].to_i){ |i|
          @all_credentials << @tariff.buy!(:username => params[:username], :comment => params[:comment])
        }
        session[:hotspot_buy_block] = true
        render :template => 'hotspot/buy_batch_done' and return
      end
   end
 
  
   @page_title = _("Buy Hotspot Internet (Batch-Mode)")
   
   @tariffs = @session[:user].customer.dial_tariffs
   if !session[:hotspot_buy_block] then
 
     @tariff_id = params[:tariff_id]
     @username = params[:username]
     @comment = params[:comment]
   end

   session[:hotspot_buy_block] = false

 end

 
end


