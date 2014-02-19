
class Numeric
  def to_datasize
    return "%.2f Gb" % (self.to_f/(1024**3)) if self > 1024**3
    return "%.1f Mb" % (self.to_f/(1024**2)) if self > 1024**2
    return "%.1f Kb" % (self/1024) if self > 1024*32
    return "#{self.to_s} Bytes"
  end
  
  def to_money(human_style = false)
    human_style = false		# <= breaking csv export
    if human_style then
      neg =  self.to_i < 0 ? '-' : ''
      tp = (self.to_i.abs / 100).to_s.reverse.split(/(...)/).delete_if { |e| e.empty? }.map { |e| e.reverse}.reverse      
      "%s%s.%02d" % [neg, tp.join(','), (self % 100)]
    else
      "%d.%02d" % [ self / 100, self % 100]
    end
  end
  
  def to_timeframe
     t = self.to_i
     res = ''
     if t > 86400 then
       d = (t / 86400)
       res << "%d day#{d > 1 ? 's' : ''} " % d
       t = t % 86400
     end

     res << "%02dh" % (t / 3600)
     t = t % 3600
     
     res << "%02dm" % (t / 60)
     t = t % 60
     
     res
  end
end

class String
  def ord		# 'A' => 65
    i = self[0]
    return i if i.kind_of?(Numeric)	# ruby 1.8

    eval('?'+i)		# ruby 1.9 (hack)    
  end
  def chr
    self[0]
  end
  
  def sql_e		# sql escape
    gsub(/\\|'/) { |c| "\\#{c}" }
  end

  def shorten(max_characters = 20)
     length > max_characters ? self[0..(max_characters-4)]+'...' : self
  end
  
  def html_e 		# fake html escaper
     gsub(/\</, '&lt;').gsub(/\>/, '&gt;')
  end
  
  def t # there are about 200 old "string".t calls.. TODO fixthat
    self
  end
  
end

class Time

  def hdatetime
    ("%02d/%02d/%d %02d:%02d" % [self.day, self.month, self.year, self.hour, self.min]) rescue nil
  end
  def hdate
    "%02d/%02d/%d " % [self.day, self.month, self.year]
  end
  
  # 20100912
  def cdate(with_time = false)
    with_time ? \
       "%04d%02d%02d%02d%02d" % [self.year, self.month, self.day, self.hour, self.min] \
              : \
       "%04d%02d%02d" % [self.year, self.month, self.day]         
  end
  
  def self.hdateparse(d)
    raise ArgumentError, "Bad Format (dd/mm/yyyy)" unless d =~ /(\d+)\/(\d+)\/(\d+)/
    
    (d,m,y) = [$1, $2, $3]
    
    t = Time.parse("#{m}/#{d}/#{y}")
    
     # this happens if you do 31/09/2010 for example
    raise ArgumentError, "Out of Range" if m.to_i != t.month
    t
  end
  
  def holiday?
    wday == 0   # fixme: add holidays!!
  end
  
  def workday?
    (1..5).include?(wday)
  end
  
  def saturday?
     wday == 6
  end
  
  # fuzzy compare
  def fuzzy_eql(other, tolerance_seconds = 5)
    (self.to_i - other.to_i).abs < tolerance_seconds
  end
  
  def same_day?(other)
    Time.hdateparse(self.hdate).fuzzy_eql(Time.hdateparse(other.hdate),1)
  end
  
end


class Range
  # check if this range includes or overlapps the other range
  def rinclude?(other)
    raise ArgumentError, "Need another range" unless other.kind_of?(Range)
    (other.first > self.first &&  other.first < self.last) ||
    (other.last > self.first && other.last < self.last) ||
    (other.first < self.first && other.last > self.last)    
  end
end


class NilClass
 def to_money(human_style = false)
   'undefined'
 end
end


class File
  
  # Opens a new file for writing - will generate unique filename
  # Unlike ruby's Tempfile - this one will not be deleted automatically.
  def self.open_temp(base_name, suffix = nil)
    begin 
      time_now = Time.now
      filename = base_name + ("-%04d%02d%02d-%02d%02d%02d-%d" % [time_now.year, time_now.month, time_now.day, 
                  time_now.hour, time_now.min, time_now.sec, time_now.usec])
      filename += '.' + suffix if suffix
    end while (File.exist?(filename))
    File.open(filename, 'w+')
  end
end


