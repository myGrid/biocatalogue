# BioCatalogue: app/controllers/service_responsibles_controller.rb
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details.

class ServiceResponsiblesController < ApplicationController
  
  before_filter :find_service_responsible, :only => [:activate, :deactivate]
  
  before_filter :login_required, :only =>[:activate, :deactivate]
  
  before_filter :authorise, :only => [:activate, :deactivate]
  
  
  def new
    @service_responsible = ServiceResponsible.new
    
    respond_to do |format|
      format.html {redirect_to @service_responsible.service}
    end
    
  end
  
  def create
    @service_responsible = ServiceResponsible.new(params[:service_responsible])
    
    respond_to do |format|
      if @service_responsible.save
        flash[:notice] = "New Responsible has been assigned"
        format.html{ redirect_to @service_responsible.service}
        format.xml {disable_action}
      else
        flash[:error] = "Could not assign new responsible"
        format.html { redirect_to(@service) }
        format.xml {disable_action}
      end
    end
  end
  
  
  def deactivate

    respond_to do |format|
      if @service_responsible.deactivate!
        flash[:notice] = "<div class=\"flash_header\">You have been removed from the status notification list for #{@service_responsible.service.display_name}</div><div class=\"flash_body\">.</div>"
        format.html{redirect_to(user_url(@service_responsible.user, :id => @service_responsible.user.id, :page => @page, :anchor =>'status-notifications')) }
        format.xml { disable_action }
      else
        flash[:notice] = "<div class=\"flash_header\">Could not remove you from status notification list for #{@service_responsible.service.display_name}</div><div class=\"flash_body\">.</div>"
        format.html{redirect_to(user_url(@service_responsible.user, :id => @service_responsible.user.id, :anchor =>'status-notifications')) }
        format.xml { disable_action }
      end
    end
  end
  
  def activate

    respond_to do |format|
      if @service_responsible
        if @service_responsible.activate!
          flash[:notice] = "<div class=\"flash_header\">You have been added to status notification list for #{@service_responsible.service.display_name}</div><div class=\"flash_body\">.</div>"
          format.html{ redirect_to(user_url(@service_responsible.user, :id => @service_responsible.user.id, :page => @page, :anchor =>'status-notifications')) }
          format.xml { disable_action }
        else
          flash[:error] = "<div class=\"flash_header\">Could not add you to the status notification list for #{@service_responsible.service.display_name}</div><div class=\"flash_body\">.</div>"
          format.html{ redirect_to(user_url(@service_responsible.user, :id => @service_responsible.user.id, :anchor =>'status-notifications')) }
          format.xml { disable_action }
        end
      end
    end
  end

  private 
  
  def find_service_responsible
    @service_responsible = ServiceResponsible.find(params[:id])
  end
  
  def authorise
    unless BioCatalogue::Auth.allow_user_to_curate_thing?(current_user, @service_responsible.service)
      flash[:error] = "You are not allowed to perform this action!"
      redirect_to @service_responsible.service
    end
  end

end
