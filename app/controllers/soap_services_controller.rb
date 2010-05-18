# BioCatalogue: app/controllers/soap_services_controller.rb
#
# Copyright (c) 2008-2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details.


class SoapServicesController < ApplicationController
  
  before_filter :disable_action, :only => [ :index, :edit, :update, :destroy, :bulk_new, :bulk_create ]
  before_filter :disable_action_for_api, :except => [ :show, :annotations, :operations, :deployments, :wsdl_locations ]
  
  before_filter :login_required, :except => [ :index, :show, :annotations, :operations, :deployments, :wsdl_locations, :latest_wsdl ]
  
  before_filter :find_soap_service, :only => [ :show, :annotations, :operations, :deployments, :latest_wsdl ]
  
  # GET /soap_services/1
  # GET /soap_services/1.xml
  def show
    respond_to do |format|
      format.html { disable_action }
      format.xml  # show.xml.builder
    end
  end

  # GET /soap_services/new
  # GET /soap_services/new.xml
  def new
    @soap_service = SoapService.new
    params[:annotations] = { }

    respond_to do |format|
      format.html # new.html.erb
      
      # TODO: the xml template returned should only really have one field here - wsdl_location 
      format.xml  { render :xml => @soap_service }
    end
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
      @soap_service = SoapService.new(:wsdl_location => wsdl_location)
      success, data = @soap_service.populate
      
      # Check for a duplicate
      @existing_service = SoapService.check_duplicate(wsdl_location, data["endpoint"])
      
      if !@existing_service.nil?
        respond_to do |format|
          format.html { render :action => "new" }
          format.xml  { render :xml => '', :status => :unprocessable_entity }
        end
      else
        respond_to do |format|
          if success
            success = @soap_service.submit_service(data["endpoint"], current_user, params[:annotations].clone)
            if success
              flash[:notice] = 'Service was successfully submitted.'
              format.html { redirect_to(@soap_service.service(true)) }
              
              # TODO: should this return the top level Service resource or SoapService? 
              format.xml  { render :xml => @soap_service, :status => :created, :location => @soap_service }
            else
              flash.now[:error] = 'An error has occurred with the submission. Please <a href="/contact">contact us</a> to report this. Thank you.'
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

  def load_wsdl
    params[:annotations] = { }
    
    wsdl_location = params[:wsdl_url] || ''
    wsdl_location = Addressable::URI.parse(wsdl_location).normalize.to_s unless wsdl_location.blank?
    
    if wsdl_location.blank?
      @error_message = "Please provide a valid WSDL URL"
      @error_message_details = ""
    else
      @soap_service = SoapService.new(:wsdl_location => wsdl_location)
      
      err_text = "Failed to load the WSDL URL provided.<br/>" +
        "Please check that it points to a valid WSDL file.<br/>" +
        "If this problem persists, please <a href='/contact'>contact us</a>"
      
      begin
        @wsdl_info, err_msgs, wsdl_file = BioCatalogue::WsdlParser.parse(@soap_service.wsdl_location)
        
        # Check for a duplicate
        @existing_service = SoapService.check_duplicate(wsdl_location, @wsdl_info["endpoint"])
        
        # Only continue we have valid wsdl_info or if no duplicate was found
        unless @wsdl_info.blank?
          if @existing_service.nil?
            if err_msgs.empty?
              @error_message = nil
              
              # Try and find location of the service from the url of the endpoint
              @wsdl_geo_location = BioCatalogue::Util.url_location_lookup(@wsdl_info["endpoint"])
            else
              @error_message = err_text
              @error_message_details = err_msgs.to_sentence
            end
          else
            # Submit a job to run the service updater
            BioCatalogue::ServiceUpdater.submit_job_to_run_service_updater(@existing_service.id)
          end
        else
          @error_message = err_text
          @error_message_details = err_msgs.to_sentence
        end
      rescue Exception => ex
        @error_message = err_text
        @error_message_details = ex.message
        BioCatalogue::Util.yell("Failed to load WSDL from URL - #{wsdl_location}.\nException: #{ex.message}.\nStack trace: #{ex.backtrace.join('\n')}")
      end
    end
    respond_to do |format|
      format.html { render :partial => "after_wsdl_load" }
      format.js { render :partial => "after_wsdl_load" }
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
    @soap_service      = SoapService.new #(params[:soap_service])
    @new_services      = []
    @existing_services = []
    @error_urls        = []
    urls               = []
    
    params[:url_list].each { |line|
    urls << line.strip if line =~ /http:/ or line =~ /https:/}
    if urls.empty?
      @soap_service.errors.add_to_base('No service urls were found!')
      render :action =>'bulk_new'
    else
      
        urls.each do |url|
          begin
            if SoapService.find(:first, :conditions => ["wsdl_location = ?", url])
              @soap_service = SoapService.find(:first, :conditions => ["wsdl_location = ?", url])
              @existing_services << @soap_service.service(true) if @soap_service != nil
            else
              @soap_service = SoapService.new({:wsdl_location => url})        
              success, data = @soap_service.populate
              if success and @soap_service.save
                pc_success = @soap_service.post_create(data['endpoint'], current_user)
                if pc_success 
                  @new_services << @soap_service.service(true)
                  flash[:notice] = 'SoapService was successfully created.'
                else
                  @soap_service.errors.add_to_base("Service with url, #{url}, was not saved. post_create failed!")
                  @error_urls << url
                end 
              else
                @soap_service.errors.add_to_base("Service with url, #{url}, was not saved")
                render(:action => 'new') and return
              end
            end
          rescue Exception => ex
            @error_urls << url
            logger.error("Failed to register service - #{url}. Bulk registration Exception:")
            logger.error(ex)
          end
      end
    end
     @services = @new_services.paginate({:page => params[:page], 
                                                :order => "created_at DESC", 
                                                :per_page => 10})   
  end
  
  def annotations
    respond_to do |format|
      format.html { disable_action }
      format.xml { redirect_to(generate_include_filter_url(:ass, @soap_service.id, "annotations", :xml)) }
      format.json { render :json => @soap_service.annotations.paginate(:page => @page, :per_page => @per_page).to_json }
    end
  end
  
  def operations
    respond_to do |format|
      format.html { disable_action }
      format.xml  # operations.xml.builder
    end
  end
  
  def deployments
    respond_to do |format|
      format.html { disable_action }
      format.xml  # deployments.xml.builder
    end
  end
  
  def wsdl_locations
    @wsdl_locations = SoapService.find(:all, :select => "wsdl_location").map { |s| s.wsdl_location }.uniq.compact
    respond_to do |format|
      format.html { disable_action }
      format.xml  # wsdl_locations.xml.builder
    end
  end
  
  def latest_wsdl
    send_data(@soap_service.latest_wsdl_contents, :type => "text/xml", :disposition => 'inline')
  end
  
  protected
  
  def find_soap_service
    @soap_service = SoapService.find(params[:id])
  end
  
end
