# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper


  def headline text
    ("<h1>%s</h1>" % text).html_safe
  end

  def headline_small text
    ("<h2>%s</h2>" % text).html_safe
  end


  def data_table_options(options = {})
   sProcessing = _("Processing...")
   sLengthMenu = _("Show _MENU_ entries")
   sZeroRecords = _("No matching records found")
   sInfo = _("Showing _START_ to _END_ of _TOTAL_ entries")
   sInfoEmpty = _("Showing 0 to 0 of 0 entries")
   sInfoFiltered = _("(filtered from _MAX_ total entries)")
   sInfoPostfix = ''
   sSearch = _("Search") + ":"
   sUrl = ''
   sFirst = _("First")
   sPrevious = _("Previous")
   sNext = _("Next")
   sLast = _("Last")
   iDisplayLength = options[:iDisplayLength] || 25
   sAll = _("All")
   aLengthMenu =  "[[25, 50, 100, -1], [25, 50, 100, \"#{sAll}\"]]"
   aaSorting = ''
   if options[:aaSorting]
     aaSorting = '"aaSorting": [],'
   end
  <<-OEND
  {
    #{aaSorting}
    "iDisplayLength": #{iDisplayLength},
    "aLengthMenu": #{aLengthMenu},
    "oLanguage": {
	"sProcessing":   "#{sProcessing}",
	"sLengthMenu":   "#{sLengthMenu}",
	"sZeroRecords":  "#{sZeroRecords}",
	"sInfo":         "#{sInfo}",
	"sInfoEmpty":    "${sInfoEmpty}",
	"sInfoFiltered": "#{sInfoFiltered}",
	"sInfoPostFix":  "#{sInfoPostfix}",
	"sSearch":       "#{sSearch}",
	"sUrl":          "#{sUrl}",
	"oPaginate": {
	    "sFirst":    "#{sFirst}",
	    "sPrevious": "#{sPrevious}",
	    "sNext":     "#{sNext}",
	    "sLast":     "#{sLast}"
	}
    }
}
OEND
  end
  
  
  

  def flash_message
    r = ''
#    return flash.inspect
#    return '' unless flash.instance_of?(Hash)
    if flash[:notice] then
      r << "<div id=\"flash_notice\"><img src='/images/info.png' alt='Notice'/> %s</div>" % h(flash[:notice])
    end
    if flash[:error]
      r << "<div id=\"flash_error\">"+image_tag('error.png')+h(flash[:error])+"</div>"
    end
    r.html_safe
  end
  
  # Renders an Location object
  def render_location(location)
    r = get_company_name
    rr = ''
    location.each do |l|
     if !l[:linkto].instance_of?(Hash) then
       rr+=' -&gt; '+l[:text]
     else
      rr+=' -&gt; '+link_to(l[:text], l[:linkto]).html_safe
     end
    end
    r.to_s.html_safe+rr.to_s.html_safe
 end

# ascii arrow link
  def alink_to(text, to, options={})
    if to.instance_of?(Hash) then
      to[:locale] ||= params[:locale]	# this fixes link_to :action => 'index' not linking locales
      out = "<b>---&gt; " + link_to(text, to, options) + "</b>"
    else
      out = "<b>---&gt; <a href=\"%s\">%s</a></b>" % [to, text]
    end
    out.html_safe
  end
  
  # link in brackets
  def blink_to(text, to, options={})
    if to.instance_of?(Hash) then
      to[:locale] ||= params[:locale]	# this fixes link_to :action => 'index' not linking locales
      out = "<b>[ " + link_to(text, to, options) + " ]</b>"
    else
      out = "<b>[ <a href=\"%s\">%s</a></b>" % [to, text]
    end
    out.html_safe
  end
  
  # link as a button
  def btlink_to(text, to, icon=nil)
    r= "<div class='vmenu'><a href='"+url_for(to)+"'>"
    r+=image_tag(icon, :border=>0) if icon
    r+="<br><b>"+ text + "</b></a></div>"
    r.html_safe
  end
  
  
    
  def text_empty if_empty, text
    if text.nil? or text.empty?
      if_empty.html_safe
    else
      text.html_safe
    end
  end

  # displays errors in an activrecord errors struct - or String
  def error_messages mod
   if mod.instance_of?(String) then
     x= "<b>" + "Errors".t + "</b><br>#{mod}"    
     return x.html_safe
   end
  
   return if mod.errors.count == 0
   r = "<b>"+_("Errors")+"</b><ul>"
   mod.errors.each do | f,v |
     r+="<li><b>"+h(f)+"</b> - "+h(v)+"</li>"
   end
   r += "</ul>"
   r.html_safe
  end
  
  def small t
    return ("<small>"+t+"</small>").html_safe
  end
  
  # displays a list of errors passed in an array
  def error_messages_simple(a)
    return if a.empty?
    r = "<b>" + _("Errors") + "</b><ul>"
    a.each { |i| r+="<li>#{h(i)}</li>\n" }
    r+="</ul>\n"
    r.html_safe
  end
  
  def nice_balance(b)
    if b <= 0 then
      "<tt style='color:green'>+#{b.abs.to_money}</tt>".html_safe
    else
      "<tt style='color:red'>-#{b.abs.to_money}</tt>".html_safe
    end
  end
  
  
#  
#  def csrf_meta_tag
#    if protect_against_forgery?
#      out = %(<meta name="csrf-param" content="%s"/>\n)
#      out << %(<meta name="csrf-token" content="%s"/>)
#      out % [ Rack::Utils.escape_html(request_forgery_protection_token),
#              Rack::Utils.escape_html(form_authenticity_token) ]
#    end
#    out.html_safe
#  end


  def state_picture(circuit_state)
    p = [].tap do |pic|
       pic << ['status-unmonitored.png',
               _('Circuit can not be monitored')] and next unless circuit_state
       pic << ['status-up-ping.png',
               _('We can ping the CPE')] if circuit_state.up? && 
                                           circuit_state.monitor == 'ping'
       pic << ['status-up-mac.png',
               _('We can not ping the CPE but we see its MAC address')] \
                 if circuit_state.up? && circuit_state.monitor == 'mac'
       pic << ['status-down.png',
               _('Circuit is monitored DOWN')] if circuit_state.down?
    
       pic << ['status-unmonitored.png',
               _('Circuit can not be monitored')] if pic.empty?
    end.first
    
    t = p[1]
    if circuit_state then
      t = p[1] + " " + _("(last checked: %s ago)" % (Time.now - circuit_state.last_update).to_timeframe)
    end
    "<img src='/images/#{p[0]}' title='#{t}' alt='#{t}'>".html_safe
  end



 def rbuttons(name, tag_name)
   r = "<td>#{name}</td>"
   (0..4).each do |score|   
    checked = (params[tag_name].to_i == score)
    checked = true if !params[tag_name] && score == 2
    r << "<td>#{radio_button_tag tag_name, score.to_s, checked }</td>\n"
   end
   r << "</td>"
   r.html_safe
 end















  def paginating_links(paginator, options = {},foobar={})
  out = '<div class="digg_pagination">'
  out << '<div clas="page_info">'
  out << page_entries_info(paginator)
  out <<'  </div>'
  out <<  will_paginate(paginator, :container => false ).to_s
  out << '</div>'
    out.html_safe
  end
  
  
  def sort_td_class_helper(param)
    result = 'class="sortup"' if params[:sort] == param
    result = 'class="sortdown"' if params[:sort] == param + "_reverse"
    return result
  end

  def link_to_remote(name, options = {}, html_options = nil)
    html_options =  html_options || options.delete(:html)
    function = remote_function(options)
    onclick = "#{"#{html_options[:onclick]}; " if html_options[:onclick]}#{function}; return false;"
    href = html_options[:href] || '#'
    content_tag(:a, name, html_options.merge(:href => href, :onclick => onclick))
  end

  def sort_link_helper(text, param)
    key = param
    key += "_reverse" if params[:sort] == param
    options = {
        :url => url_for( params.merge({:sort => key, :page => nil})),
        :update => 'table',
        :before => "$('#spinner').show();",
        :success => "$('#spinner').hide();",
        :method=>:get
    }
    html_options = {
      :title => _("Sort by this field"),
      :href => url_for( params.merge({:sort => key, :page => nil}))
    }
    link_to_remote(text, options, html_options)
  end













end
