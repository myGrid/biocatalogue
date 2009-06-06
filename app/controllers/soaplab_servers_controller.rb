# BioCatalogue: app/controllers/soaplab_servers_controller.rb
#
# Copyright (c) 2008, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details.

class SoaplabServersController < ApplicationController
  
  #before_filter :disable_action, :only => [ :index, :show, :edit, :update, :destroy ]
  before_filter :disable_action, :only => [:index, :edit, :update, :destroy ]
  before_filter :login_required, :except => [ :index, :show ]
  
  # GET /soaplab_servers
  # GET /soaplab_servers.xml
  def index
    @soaplab_servers = SoaplabServer.find(:all, :order => 'id DESC')

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
                                   :per_page => 10,
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
    @soaplab_server = SoaplabServer.new(params[:soaplab_server])

    respond_to do |format|
      if @soaplab_server.save
        new_wsdl_urls, existing_services, error_urls = @soaplab_server.save_services(current_user)
        flash[:notice] = 'SoaplabServer was successfully created.'
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
      @soap_service = SoapService.new(:wsdl_location => wsdl_location)
      @soaplab_server = SoaplabServer.new(:location =>wsdl_location)
      begin
        @wsdl_info, err_msgs, wsdl_file = BioCatalogue::WsdlParser.parse(@soap_service.wsdl_location)
        @wsdl_info["tools"] = @soaplab_server.services_factory().values.flatten.collect{ |v| v['name']}.sort
        @wsdl_geo_location = BioCatalogue::Util.url_location_lookup(wsdl_location)
      rescue Exception => ex
        @error_message = "Failed to load the WSDL location provided."
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
