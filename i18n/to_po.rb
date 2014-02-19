langfile = File.read('pt.lng')

ofound = ''
langfile.split(/\n/).each do |line|
  if ofound && line =~ /^T\s\'(.*)\'/ then
     to = $1
     puts "msgid \"#{ofound}\""
     puts "msgstr \"#{to}\"\n\n"
  end
  if line =~ /^O\s\'(.*)\'/ then
    ofound = $1
#    puts "got #{ofound}"
  else
   ofound = nil
  end
end

