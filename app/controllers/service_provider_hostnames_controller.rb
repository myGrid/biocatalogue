# BioCatalogue: app/controllers/service_provider_hostnames_controller.rb
#
# Copyright (c) 2008-2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details.

class ServiceProviderHostnamesController < ApplicationController
  
  before_filter :disable_action, :except => [ :reassign_provider_by_popup, :reassign_provider ]
  
  before_filter :find_service_provider_hostname
  
  before_filter :authorise
  
  def reassign_provider_by_popup
    respond_to do |format|
      format.js { render :layout => false }
    end
  end
  
  def reassign_provider
    service_provider_name = params[:name] || ""
    service_provider_name.chomp!
    service_provider_name.strip!
    
    not_changed = service_provider_name.downcase == @hostname.service_provider.name.downcase
    
    success = true
    
    if service_provider_name.blank? || not_changed # complain
      flash[:error] = (not_changed ? "Hostname '#{@hostname.hostname}' could not be reassigned" : "Please provide a valid provider name")
      success = false
    else # do MERGE OR CREATE NEW PROVIDER
      provider = ServiceProvider.find_by_name(service_provider_name)
      if provider.nil?
        provider = ServiceProvider.create(:name => service_provider_name)
        provider_created = true
      end
      
      if @hostname.merge_into(provider) # do MERGE
        flash[:notice] = "Hostname successfully reassigned"
      else # complain
        flash[:error] = "An error occured while reassigning this hostname to a different Service Provider.<br/>" +
                        "Please contact us if this error persists."
        provider.destroy if provider_created
        success = false
      end
    end # if name.blank? || not_changed
    
    if success
      respond_to do |format|
        format.html { redirect_to provider }
        format.xml  { head :ok }
      end      
    else # failure
      respond_to do |format|
        format.html { redirect_to service_provider_url(@hostname.service_provider) + "#hostnames" }
        format.xml  { render :xml => '', :status => 406 }
      end
    end # if success
  end
  
protected
  
  def authorise
    unless BioCatalogue::Auth.allow_user_to_curate_thing?(current_user, @hostname)
      error_to_back_or_home("You are not allowed to perform this action")
      return false
    end
    
    return true
  end

private
  
  def find_service_provider_hostname
    @hostname = ServiceProviderHostname.find(params[:id])
  end
  
end
