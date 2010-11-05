# BioCatalogue: app/controllers/fail_controller.rb
#
# Copyright (c) 2009, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details.

class FailController < ApplicationController
  
  before_filter :login_required
  
  before_filter :authorise
  
  # GET /fail/:http_code
  def index
    case params[:http_code]
      when "404"
        raise ActiveRecord::RecordNotFound.new
      when "500"
        x = nil
        x.hello_world
    end
    
    respond_to do |format|
      format.html # index.html.erb
    end
  end
  
  private
  
  def authorise
    unless current_user.is_admin?
      flash[:error] = "You are not allowed to perform this action"
      redirect_to_back_or_home
    end
    return true
  end
  
end
