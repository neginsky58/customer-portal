
class CircuitTraffic < ActiveRecord::Base
   
   
   self.table_name = 'circuit_traffic'
   belongs_to :circuit

   def h_time_tag
       if time_tag =~ /^MO.*/ then
          year, month = time_tag.scan(/^MO(\d+)\.(\d+)/).flatten
          return "#{year}/#{month}"
       end
   end
   
   def total
      total_in + total_out
   end

   # Update a circuit traffic info with current ifIn and ifOutOctets
   # returns [difference_in, difference_out]
   def self.update(circuit, cin, cout)
     tt = circuit.traffic_time_tag
       
     ct = CircuitTraffic.find(:first, :conditions => ["circuit_id = ? AND time_tag = ?", circuit.id, tt])
     if !ct then		# create new record
       last_cin = cin
       last_cout = cout
       last_seq = 0
       last_ct = CircuitTraffic.find(:first, 
                                     :conditions => ["circuit_id = ?", circuit.id], 
                                     :order => "seq desc")
       if last_ct then
         last_ct.stop = Time.now		# close previous record and save counters
         last_ct.save!
         last_cin, last_cout = last_ct.last_cin, last_ct.last_cout
         last_seq = last_ct.seq
       end
       ct = CircuitTraffic.new		# create new one, copy counter values
       ct.start = Time.now
       ct.stop  = nil
       ct.time_tag = tt
       ct.circuit = circuit
       ct.last_cin = last_cin
       ct.last_cout = last_cout
       ct.total_in = 0
       ct.total_out = 0
       ct.seq = last_seq + 1
       ct.save!
     end
       
       		# now update ct
     diff_in   = cin < ct.last_cin ? cin : cin - ct.last_cin
     diff_out  = cout < ct.last_cout ? cout : cout - ct.last_cout
     ct.total_in = ct.total_in + diff_in
     ct.total_out = ct.total_out + diff_out
     ct.last_cin = cin
     ct.last_cout = cout
     ct.last_update = Time.now
     ct.save!
     return [diff_in, diff_out]
  end

end

