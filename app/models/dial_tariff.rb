#encoding: utf-8
class DialTariff < ActiveRecord::Base
 
 self.table_name = 'dial_tariffs'
 validates_presence_of :name
 validates_length_of :name, :within => 3..128
 
 belongs_to :customer
 
 def validate
#   raise self.inspect
   if self.dial_type == 'VOLUME' && self.data_credit.to_i <= 0 then
       errors.add('data_credit', 'You need to set a volume limit for this type')       
   end
   if self.dial_type == 'TIME' && self.time_credit <= 0 then
       errors.add('time_credit', 'You need to set a time limit for this type')       
   end
 end
 
 # http://refactormycode.com/codes/785-converting-all-umlaut-characters-to-their-base
 def convert_umlaut_to_base(input)
    text = input.dup
    %w[áäa ÁÄÅA óöo ÓÖO íi ÍI úüu ÚÜU ée ÉE ßs çc ÇC âa ÂA áa ÀA ãa].each do |set|
      text.gsub!(/[#{set[0..-2]}]/,set[-1..-1])
    end
    text
  end
  
 # http://snippets.dzone.com/posts/show/2137
 def random_pronouncable_password(size = 4)
  c = %w(b c d f g h j k l m n p qu r s t v w x z ch cr fr nd ng nk nt ph pr rd sh sl sp st th tr)
  v = %w(a e i o u y)
  f, r = true, ''
  (size * 2).times do
    r << (f ? c[rand * c.size] : v[rand * v.size])
    f = !f
  end
  r
 end
 
 
 def valid_username?(un)
    return false if un.size < 5
    return false if DialProfile.find(:first, :conditions => ['username = ? and status = ?', un, 'A'])
    return false if User.find(:first, :conditions => ['username = ?', un])
    true
 end
 
 def mk_username(base)
    base = convert_umlaut_to_base(base.strip).downcase
    
    # shorten firstname lastname
    if (base.include?(' ') && base.size > 6) then
         a = base.split(' ')
         base = a[0][0].chr + '.'+ a[1..-1].join
    end

    # make up something at least 5 characters long    
    while base.size < 5 do
       base+=rand(10).to_s
    end
    
    base = base.gsub(/[^a-zA-Z0-9\.\-\_]/, '')
    username = base.dup
    username = username[0..19]
    while (!valid_username?(username))
        username = "#{base}%05d" % rand(99999)
    end
    username    
 end

 def mk_password
   "#{random_pronouncable_password(4)[0..5]}%02d" % rand(99)
 end
 
 def buy_dial_profile(customer, options = {})
   dp = DialProfile.new
   dp.customers << customer
   dp.username = mk_username(options[:username] || '')
   dp.comment = options[:comment] || ''
   dp.password = mk_password
   dp.radius_group = self.radius_group
   dp.radius_user  = nil
   
   if self.dial_type == 'VOLUME' then
     dp.dial_type = 'VOLUME'
     dp.data_credit = self.data_credit
   end
   
   if self.dial_type == 'TIME' then
     dp.dial_type = 'TIME'
     dp.valid_until = Time.now + self.time_credit
   end
   
   if self.dial_type == 'RELTIME' then
     dp.dial_type = 'RELTIME'
     dp.time_credit = self.time_credit
   end
   
   raise "dial_type unknown: #{self.dial_type}" unless dp.dial_type
   
   dp.created = Time.now
   dp.status = 'A'
   dp.save!
   
   dp
 end
 
 # returns dial_profile
 def buy!(options = {})
   dp = nil

   self.class.transaction do
     dp = buy_dial_profile(self.customer, options)
     
     journal = Journal.new
     journal.source_id = 'dial_tariff_buy'     
     info = "Hotspot: #{self.name}, User: #{dp.username}"
     info += ", comment: #{options[:comment]}" unless options[:comment].to_s.empty?
     journal.info = info
     journal.created = Time.now()
     journal.save!
     
     customer.main_account.debit(self.price, customer.agent.sales_account, journal)
     customer.add_log("Purchased Tariff: #{info}", :id_string => 'dial_tariff::buy', 
                                                   :user => options[:user])     
   end
   dp  
 end
end

