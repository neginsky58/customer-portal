
class ContactController < ApplicationController

  def list
    @contacts = @session[:user].customer.contacts.delete_if { |c| c.private }.sort { |a,b| a.lastname <=> b.lastname  }
  end

  def add
    render :text => 'works'
  end

end

