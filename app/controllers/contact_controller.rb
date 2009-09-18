# BioCatalogue: app/controllers/contact_controller.rb
#
# Copyright (c) 2008, University of Manchester, The European Bioinformatics
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details.

class ContactController < ApplicationController
  # GET /contact
  def index
    respond_to do |format|
      format.html # index.html.erb
    end
  end

  def create
    from_user = params[:from] || current_user.try(:display_name) || "no name specified"
    from_user += ' (' + (params[:email] || current_user.try(:email) || 'no email specified') + ')'

    if params[:content].length == params[:length_check].to_i
      ContactMailer.deliver_feedback(from_user, params[:subject], params[:content])

      respond_to do |format|
        flash[:notice] = 'Your message has been submitted. Thank you very much.'
        format.html { redirect_to contact_url }
      end
    else
      respond_to do |format|
        flash[:error] = 'Your message has not been submitted. The message length was not entered correctly.'
        format.html { render :action => :index }
      end
    end

  end
end
