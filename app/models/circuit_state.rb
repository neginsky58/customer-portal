class CircuitState < ActiveRecord::Base
       
       self.table_name = 'circuit_states'
       has_many :circuit_state_logs
       
       belongs_to :circuit
       
       def down?
         state == 'D'
       end
       
       def up?
         state == 'U'
       end
       
       def hstate
          case state
            when 'U' then 'UP'
            when 'D' then 'DOWN'
            else  'unmonitored'
          end
       end
       
       def _sh(h)
        return h.split(':').map {|e| e.to_i} if h.include?(':')
        [h.to_i, 0]
       end
       
       # if circuit has active monitoring it will check for date, time
       def monitored_now?
         tf = circuit.monitoring_setting.todays_monitoring_times
         return false unless tf 
        
         from,to = tf.split('-').map { |e| ("%02d%02d" % _sh(e)).to_i }
         now     = ("%02d%02d" % [Time.now.hour, Time.now.min]).to_i
         
         $stderr.puts "#{from} #{to} - #{now}"
         
         (from..to).include?(now)
       end
       
       def log(txt, sysmsg, user)
          cs = CircuitStateLog.new do |cs|
            cs.circuit_state = self
            cs.user_id = user ? user.id : nil
            cs.created = Time.now
            cs.message = txt
            cs.sysmessage = sysmsg
          end
          cs.save!
       end
       
       def logs
          circuit_state_logs.sort_by { |cs| cs.created }.reverse
       end
       
       def last_update_user
          logs.last.user rescue nil
       end
       
       def monitoring_state
         read_attribute(:monitoring_state) || 'NEW'
       end

end

