# BioCatalogue: app/controllers/soap_services_controller.rb
#
# Copyright (c) 2008, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details.

require 'wsdl_parser'
require 'addressable/uri'

class SoapServicesController < ApplicationController
  before_filter :login_required, :except => [:index, :show]
  
  # GET /soap_services
  # GET /soap_services.xml
  def index
    #@soap_services = SoapService.find(:all, :order => "id DESC")
    @soap_services = SoapService.paginate :all, :page => params[:page], 
                                                :order => "created_at DESC", 
                                                :per_page => 10
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @soap_services }
      format.rss  { render :rss => @soap_services, :layout => false}
    end
  end

  # GET /soap_services/1
  # GET /soap_services/1.xml
  def show
    @soap_service = SoapService.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @soap_service }
      format.rss  { render :rss => @soap_service, :layout => false}
    end
  end

  # GET /soap_services/new
  # GET /soap_services/new.xml
  def new
    @soap_service = SoapService.new

    respond_to do |format|
      format.html # new.html.erb
      
      # TODO: the xml template returned should only really have one field here - wsdl_location 
      format.xml  { render :xml => @soap_service }
    end
  end

  # GET /soap_services/1/edit
  def edit
    @soap_service = SoapService.find(params[:id])
  end

  # POST /soap_services
  # POST /soap_services.xml
  def create
    wsdl_location = params[:soap_service][:wsdl_location] || ""
    wsdl_location = Addressable::URI.parse(wsdl_location).normalize.to_s unless wsdl_location.blank?
    
    if wsdl_location.blank?
      @error_message = "Please provide a valid WSDL URL"
      respond_to do |format|
        format.html { render :action => "new" }
        format.xml  { render :xml => '', :status => 406 }
      end
    else
      # Check for a duplicate
      @existing_soap_service = SoapService.find(:first, :conditions => ["wsdl_location = ?", wsdl_location])
      
      if !@existing_soap_service.nil?
        respond_to do |format|
          format.html { render :action => "new" }
          format.xml  { render :xml => '', :status => 406 }
        end
      else
        @soap_service = SoapService.new(:wsdl_location => wsdl_location)
        success, data = @soap_service.populate
        
        # TODO: store the extra information provided in the form, as Annotations.
        
        respond_to do |format|
          if success and @soap_service.save
            success = post_create(@soap_service, data["endpoint"])
            
            if success
              flash[:notice] = 'Service was successfully created.'
              format.html { redirect_to(@soap_service.service(true)) }
              
              # TODO: should this return the top level Service resource or SoapService? 
              format.xml  { render :xml => @soap_service, :status => :created, :location => @soap_service }
            else
              flash[:error] = 'An error has occurred with the submission. Please contact us to report this. Thank you.'
              format.html { render :action => "new" }
              format.xml  { render :xml => '', :status => 500 }
            end
          else
            format.html { render :action => "new" }
            format.xml  { render :xml => @soap_service.errors, :status => :unprocessable_entity }
          end
        end
      end
    end
    
  end

  # PUT /soap_services/1
  # PUT /soap_services/1.xml
  def update
    @soap_service = SoapService.find(params[:id])

    respond_to do |format|
      if @soap_service.update_attributes(params[:soap_service])
        flash[:notice] = 'SoapService was successfully updated.'
        format.html { redirect_to(@soap_service) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @soap_service.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /soap_services/1
  # DELETE /soap_services/1.xml
  def destroy
    @soap_service = SoapService.find(params[:id])
    @soap_service.destroy

    respond_to do |format|
      format.html { redirect_to(soap_services_url) }
      format.xml  { head :ok }
    end
  end
  
  def load_wsdl
    wsdl_location = params[:wsdl_url] || ''
    wsdl_location = Addressable::URI.parse(wsdl_location).normalize.to_s unless wsdl_location.blank?
    
    if wsdl_location.blank?
      @error_message = "Please provide a valid WSDL URL"
    else
      # Check for a duplicate
      @existing_soap_service = SoapService.find(:first, :conditions => ["wsdl_location = ?", wsdl_location])
      
      # Only continue if no duplicate was found
      if @existing_soap_service.nil?
        @soap_service = SoapService.new(:wsdl_location => wsdl_location)
        
        begin
          @wsdl_info, err_msgs, wsdl_file = BioCatalogue::WsdlParser.parse(@soap_service.wsdl_location)
          
          if err_msgs.empty?
            @error_message = nil
            
            # Try and find location of the service from the url of the WSDL.
            @wsdl_geo_location = BioCatalogue::Util.url_location_lookup(@soap_service.wsdl_location)
          else
            @error_message = "Error messages: #{err_msgs.to_sentence}."
          end
        rescue Exception => ex
          @error_message = "Failed to load the WSDL location provided."
          logger.error("ERROR: failed to load WSDL from location - #{wsdl_location}. Exception:")
          logger.error(ex)
        end
      end
    end
    respond_to do |format|
      format.html { render :partial => "after_wsdl_load" }
      format.xml  { render :xml => '', :status => 406 }
    end
  end
  
  def bulk_new
    @soap_service = SoapService.new

    respond_to do |format|
      format.html # bulk_new.html.erb
      format.xml  { render :xml => @soap_service }
    end
  end
    
  def bulk_create
    @soap_service = SoapService.new #(params[:soap_service])
    
    urls = []
    params[:soap_service][:description].each { |line|
    urls << line.strip if line =~ /http:/ or line =~ /https:/}
    if urls.empty?
      @soap_service.errors.add_to_base('No service urls were found!')
      render :action =>'bulk_new'
    else
      urls.each do |url|
        @soap_service.wsdl_location = url
        @soap_service.get_service_attributes
        if @soap_service.save
          flash[:notice] = 'SoapService was successfully created.'
        else
          @soap_service.errors.add_to_base("Service with url, #{url}, was not saved")
          render(:action => 'new') and return
        end
      end
    end
  end
  
protected

  def post_create(soap_service, endpoint)
    # Try and find location of the service from the url of the WSDL.
    wsdl_geo_location = BioCatalogue::Util.url_location_lookup(soap_service.wsdl_location)
    city = (wsdl_geo_location.nil? || wsdl_geo_location.city.blank? || wsdl_geo_location.city == "(Unknown City)") ? nil : wsdl_geo_location.city
    country = (wsdl_geo_location.nil? || wsdl_geo_location.country_code.blank?) ? nil : CountryCodes.country(wsdl_geo_location.country_code)
    
    # Create the associated service, service_version and service_deployment objects.
    # We can assume here that this is the submission of a completely new service in BioCatalogue.
    
    new_service = Service.new(:name => soap_service.name)
    
    new_service.submitter = current_user
                              
    new_service_version = new_service.service_versions.build(:version => "1", 
                                                             :version_display_text => "1")
    
    new_service_version.service_versionified = soap_service
    new_service_version.submitter = current_user
    
    new_service_deployment = new_service_version.service_deployments.build(:endpoint => endpoint,
                                                                           :city => city,
                                                                           :country => country)
    
    new_service_deployment.provider = ServiceProvider.find_or_create_by_name(Addressable::URI.parse(soap_service.wsdl_location).host)
    new_service_deployment.service = new_service
    new_service_deployment.submitter = current_user
                                                  
    if new_service.save
      return true
    else
      logger.error("ERROR: post_create method for SoapServicesController failed!")
      logger.error("Error messages: #{new_service.errors.full_messages.to_sentence}")
      return false
    end
  end
  
end
