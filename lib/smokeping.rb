# encoding: utf-8 
class SmokepingError< StandardError;end

class Smokeping
  
  def self.enabled?
    MODULES.include?('smokeping')
  end
  
  
  def mk_sptime(t)
    "#{t.year}-#{t.month}-#{t.day} #{t.hour}:#{t.min}"
  end
  
  def initialize(circuit, options = {})
     @circuit = circuit
     @start = options[:start] || 24
     if @start.kind_of?(Numeric) then
        @start = Time.now - @start.hours
     end
     @stop = options[:stop] || Time.now
     
     @start = mk_sptime(@start)
     @stop  = mk_sptime(@stop)     
  end
  
  def graph
     script = SMOKEPING_GRAPH_SCRIPT
     cmd = "#{script} #{@circuit.id} #{@start} #{@stop}"
     image = `#{cmd}`
     ### ruby 1.8: if image !~ /^\x89\x50\x4E\x47/ then
     if image[0..3].unpack('CCCC') == [137, 80, 78, 71]   # check for "\x89PNG" header
       raise SmokepingError, "Can't generate graph: #{cmd}: #{image}"
     end
     image
  end

  
end


