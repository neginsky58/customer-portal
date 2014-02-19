
<table class='display'>
  <thead>
  <tr>
  <th><%= _('Name') %></th>
  <th><%= _('Email') %></th>
  </tr> 
  </thead>
  <tbody>
    <% @contacts.each do |c| %>
    <tr>
      <td><%= "#{c.fistname} #{c.lastname}" %></td>
      <td><%= [c.email_work, c.email_private, c.email_other].delete_if {|e| e.to_s.strip.empty? }.join('<br>') %></td>
    </tr>
    
  </tbody>
  </table>
  
<% @js << "$('table.display').dataTable(#{data_table_options(:iDisplayLength => 50)});" %>

