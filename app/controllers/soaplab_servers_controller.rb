# BioCatalogue: app/controllers/soaplab_servers_controller.rb
#
# Copyright (c) 2008, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details.

class SoaplabServersController < ApplicationController
  
  before_filter :disable_action, :only => [:edit, :update, :destroy ]
  before_filter :disable_action_for_api
  
  before_filter :login_or_oauth_required, :except => [ :index, :show ]
  
  # GET /soaplab_servers
  # GET /soaplab_servers.xml
  def index
    @soaplab_servers = SoaplabServer.paginate(:page => @page,
                                              :per_page => @per_page, 
                                              :order => 'id DESC')

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @soaplab_servers }
    end
  end

  # GET /soaplab_servers/1
  # GET /soaplab_servers/1.xml
  def show
    @soaplab_server = SoaplabServer.find(params[:id])
    #@services = @soaplab_server.associated_services
    @services = Service.find(@soaplab_server.relationships.collect{ |r| r.subject_id})
    @services = @services.paginate(:page => params[:page],
                                   :per_page => @per_page,
                                   :order => 'created_at DESC',
                                   :include => [ :service_versions, :service_deployments ])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @soaplab_server }
    end
  end

  # GET /soaplab_servers/new
  # GET /soaplab_servers/new.xml
  def new
    @soaplab_server = SoaplabServer.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @soaplab_server }
    end
  end

  # GET /soaplab_servers/1/edit
  def edit
    @soaplab_server = SoaplabServer.find(params[:id])
  end

  # POST /soaplab_servers
  # POST /soaplab_servers.xml
  def create
    existing_server = SoaplabServer.find_by_location(params[:soaplab_server][:location])
    
    if existing_server.nil?
      @soaplab_server = SoaplabServer.new(params[:soaplab_server]) 
      @soaplab_server.submitter = current_user if logged_in?
    else
      @soaplab_server = existing_server
    end
    
    respond_to do |format|
      if @soaplab_server.save
        Delayed::Job.enqueue BioCatalogue::Jobs::SubmitSoaplabServices.new(@soaplab_server, current_user)
        if existing_server
          flash[:notice] = "This Soaplab server is known to #{SITE_NAME}. Any additional services will be registered."
        else
          flash[:notice] = 'Your Soaplab server submission was successfully received. Services are being submitted in the background. Please check in short while to view the services'
        end
        format.html { redirect_to(@soaplab_server) }
        format.xml  { render :xml => @soaplab_server, :status => :created, :location => @soaplab_server }
      else
        format.html { render :action => "new" }
        #format.xml  { render :xml => @soaplab_server.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /soaplab_servers/1
  # PUT /soaplab_servers/1.xml
  def update
    @soaplab_server = SoaplabServer.find(params[:id])

    respond_to do |format|
      if @soaplab_server.update_attributes(params[:soaplab_server])
        flash[:notice] = 'SoaplabServer was successfully updated.'
        format.html { redirect_to(@soaplab_server) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @soaplab_server.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /soaplab_servers/1
  # DELETE /soaplab_servers/1.xml
  def destroy
    @soaplab_server = SoaplabServer.find(params[:id])
    @soaplab_server.destroy

    respond_to do |format|
      format.html { redirect_to(soaplab_servers_url) }
      format.xml  { head :ok }
    end
  end
  
  def load_wsdl
    params[:annotations] = {'tag' =>'soaplab' }
    
    wsdl_location = params[:wsdl_url] || ''
    wsdl_location = Addressable::URI.parse(wsdl_location).normalize.to_s unless wsdl_location.blank?
    
    if wsdl_location.blank?
      @error_message = "Please provide a valid WSDL URL"
    else
      err_text = "Failed to load the WSDL URL provided.<br/>" +
        "Please check that it points to a valid WSDL file.<br/>" +
        "If this problem persists, please <a href='/contact'>contact us</a>.".html_safe
        
      @soap_service = SoapService.new(:wsdl_location => wsdl_location)
      @soaplab_server = SoaplabServer.new(:location =>wsdl_location)
      begin
        @wsdl_info, err_msgs, wsdl_file = BioCatalogue::WsdlParser.parse(@soap_service.wsdl_location)
        @wsdl_info["tools"] = @soaplab_server.services_factory().values.flatten.collect{ |v| v['name']}.sort
        @wsdl_geo_location = BioCatalogue::Util.url_location_lookup(wsdl_location)
      rescue Exception => ex
        @error_message = err_text
        logger.error("Failed to load WSDL from location - #{wsdl_location}. Exception:")
        logger.error(ex)
      end
    end
    respond_to do |format|
      format.html { render :partial => "after_wsdl_load" }
      format.xml  { render :xml => '', :status => 406 }
    end
  end
  
end
