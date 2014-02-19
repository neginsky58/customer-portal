
require 'smokeping'

class CircuitController < ApplicationController
 layout 'std'
 
 before_filter :require_login
 before_filter :find_circuit, :except => 'index'
 before_filter :mk_location
 before_filter :mk_submenu, :except => 'index'
 before_filter :check_features, :only => [:devices, :configuration]
 before_filter :check_permissions
 
  def check_permissions
   @session[:user].permission_to?('c,circuits,')
 end
 
 def check_features
    render :text => 'Access denied' and return false unless @features[:circuit_info]
 end

  def payg
    raise 'access denied' unless @session[:user].permission_to?('c,circuit_show_payg_status,r')
  end

 def mk_location
   @location.add(_('Circuits'),  { :controller => 'circuit', :action => 'index' })
   @location.add(@circuit.nice, { :controller => 'circuit', :action => 'graph', :circuit => @circuit.site }) \
      if @circuit
 end

 def mk_submenu
    return unless @features[:circuit_info]
    @submenu = []
    x = []
    x << ['graph', _('Utilization')]
    x << ['smokeping', _('Latencies/Loss')] if Smokeping.enabled?
    x << ['monitoring', _('Monitoring')]
    x << ['configuration', _('Configuration')] 
    
    x.each do |a|
       @submenu << { :title => a[1].capitalize, :controller => 'circuit', 
                   :circuit => @circuit.site, :action => a[0], :active => (a[0] == params[:action]) }
    end
 end

 def find_circuit
   @circuit = Circuit.find(:first, :conditions => ['customer_id = ? and site = ?', \
                @session[:user].customer.id, params[:circuit]])

    render :text => "Not found: #{params[:circuit]}" and return unless @circuit
 end

def display_graph
  require 'mgraph/id_string'
  require 'mgraph/rrd'

  @time = params[:time].to_i
  
  return false if @time < 0 || @time > 9000
 
  rrd = ::MGraph::RRD.new(::MGraph::IDString.new(@circuit.id_string), 
                      :customer_name => @session[:user].customer.name )
  
  png = rrd.graph(@time)
  send_data png
#  send_file fn[0], :type => 'image/png'
end


 def index
  @page_title = _("Graphs")
  @side_image = 'cables.jpg'
  online_help 'circuit-graph'
  @circuits = @session[:user].customer.circuits.dup.delete_if { |c| (!'RS'.include?(c.circuit_type) || c.status == 'D')}
 end


 
 # if we once could 'ping'-monitor the circuit, make all mac-results to DOWN
 # otherwise this is totally confusing
 private
 def normalize_states(states)
   return states if @circuit.circuit_type == 'S' # VSAT can't mac-monitor
   return states unless states.find { |e| e.monitor == 'ping' }
   mac_to_down = states.map  { |s| if s.monitor == 'mac' then
                                       s.state = 'D'
                                       s.monitor = ''
                                     end
                                     s
                            }

   new_states = []
   
   mac_to_down.reverse.each do |state|
     if new_states.empty? then
        new_states << state
        next
     end
     if state.state == 'D' && new_states[-1].state == 'D'
       new_states[-1].stop = state.stop
       next
     end
     new_states << state
   end
   new_states.reverse
 end

 public
 def monitoring
   online_help 'monitoring'
   @location.add(_("Monitoring"), { :controller => 'circuit', :action => 'monitoring', :circuit => @circuit.site })
   @page_title = _("Monitoring history for %s") % @circuit.nice

   @from = 1.month.ago
   @to   = Time.now
   
   @states = CircuitState.find(:all, :conditions =>
             ['circuit_id = ? AND
              ((stop >= ? and stop <= ?) OR
               (start >= ? and start <= ?) OR
               (start <= ? and stop is NULL))', @circuit.id, @from,@to,@from,@to,@from],
                            :order => 'start DESC')
   @ping_monitor = @circuit.circuit_type == 'S' || !!@states.find { |e| e.monitor == 'ping' }
   @states = normalize_states(@states)
#   render :text => @states.inspect and return false
   
 end

 def smokeping_generate
   @start = params['start'] || '48'
      
   @start = @start.to_i.hours.ago

   render :text => "error" unless @circuit.smokeping_enable
   
   @smokeping = Smokeping.new(@circuit, :start => @start)
   begin
      @smokeping_image = @smokeping.graph
   rescue SmokepingError => e
      @smokeping_error = e
   end
   render :partial => 'smokeping_data'
 end

 def smokeping
   online_help 'smokeping'
   @location.add(_("Latencies/Loss Graph"), { :controller => 'circuit', :action => 'smokeping', :circuit => @circuit.site })
   @page_title = _("Latencies/Loss Graph for %s" % @circuit.nice)

   if !@circuit.smokeping_enable then
     @smokeping_error = _("Latencies/Loss graph is not enabled on this circuit")
     return
   end


   @js << "$('#smokeping_data').load('smokeping_generate?circuit=#{@circuit.site}&start=48');nice_timeselect(48);"

 end
 

 def devices
   @location.add(_('Devices'), { :controller => 'circuit', :action => 'devices', :circuit => @circuit.site })   
   @page_title = _("Devices")
 end
 
 def configuration
   @location.add(_('IP configuration'), { :controller => 'circuit', :action => 'configuration', :circuit => @circuit.site })   
   @page_title = _("IP configuration")
 end

 def graph
   online_help 'circuit-graph'
   @location.add(_('Graph'), { :controller => 'circuit', :action => 'graph', :circuit => @circuit.site })   
   @page_title = _("Bandwidth Utilization for %s" % @circuit.nice)
 end
 

end
