
desc "Update pot/po files"

textdomain = 'mbms'

task :updatepo do
   require 'rubygems'
   require 'gettext/tools'
   
   version = File.read('VERSION').split(/\n/).first.strip
   
   GetText.update_pofiles(textdomain, 
             Dir.glob("{app,lib}/**/*.{rb,rhtml,erb}"), version,
             :verbose => true)
end

task :createmo do
   require 'rubygems'
   require 'gettext/tools'

   %w{de pt}.each do |lang|
     puts "Making #{lang}"
     GetText.create_mofiles(:po_root => lang, :mo_root => 'locale', :verbose => true)
   end

end

# 'createmo' is doing this
# task :installmo do
#   Dir.glob('po/*').delete_if { |e| e.include?('pot') }.each do |dir|
#      lang = dir.split('/').last
#      cmd = "install -D #{dir}/#{textdomain}.mo locale/#{lang}/LC_MESSAGES/"
#      puts cmd
#      system cmd
#   end
# end
