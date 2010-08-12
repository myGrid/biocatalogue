# BioCatalogue: app/controllers/contact_controller.rb
#
# Copyright (c) 2008-2009, University of Manchester, The European Bioinformatics
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details.

class ContactController < ApplicationController
  
  before_filter :disable_action_for_api
  
  if ENABLE_SSL && Rails.env.production?
    ssl_required :create
    ssl_allowed :all
  end
  
  # GET /contact
  def index
    respond_to do |format|
      format.html # index.html.erb
    end
  end

  def create
    from_user = params[:from] || current_user.try(:display_name) || "no name specified"
    from_user += ' (' + (params[:email] || current_user.try(:email) || 'no email specified') + ')'

    if !params[:content].blank? and (params[:content].split(/[biocat]/, -1).length == params[:length_check].to_i)
      ContactMailer.deliver_feedback(from_user, params[:subject], params[:content])

      respond_to do |format|
        flash[:notice] = 'Your message has been submitted. Thank you very much.'
        format.html { redirect_to contact_url }
      end
    else
      respond_to do |format|
        flash.now[:error] = 'Failed to submit your message. Either there was an empty message or the security number you typed in is incorrect.'
        format.html { render :action => :index }
      end
    end
  end
  
end
