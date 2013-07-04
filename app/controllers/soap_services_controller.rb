# BioCatalogue: app/controllers/soap_services_controller.rb
#
# Copyright (c) 2008-2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details.


class SoapServicesController < ApplicationController
  
  before_filter :disable_action, :only => [ :edit, :update, :destroy, :bulk_new, :bulk_create ]
  before_filter :disable_action_for_api, :except => [ :index, :show, :create, :annotations, :operations, :deployments, :wsdl_locations ]
  
  before_filter :login_or_oauth_required, :except => [ :index, :show, :annotations, :operations, :deployments, :wsdl_locations, :latest_wsdl ]
  
  before_filter :find_soap_service, :only => [ :show, :annotations, :operations, :deployments, :latest_wsdl ]

  before_filter :parse_sort_params, :only => :index
  before_filter :find_soap_services, :only => :index

  oauth_authorize :create

  def index
    respond_to do |format|
      format.html { disable_action }
      format.xml # index.xml.builder
      format.json { render :json => BioCatalogue::Api::Json.index("soap_services", json_api_params, @soap_services).to_json }
    end
  end

  # GET /soap_services/1
  # GET /soap_services/1.xml
  def show
    respond_to do |format|
      format.html { redirect_to url_for_web_interface(@soap_service), :status => 303 }
      format.xml  # show.xml.builder
      format.json { render :json => @soap_service.to_json }
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
  # Example Input
  #
  #  {
  #    "soap_service" => {
  #      "wsdl_location" => "http://webservices.genouest.org/typedservices/InterProScan.wsdl" 
  #    },
  #    "annotations" => {
  #      "documentation_url" => "doc",
  #      "alternative_names" => ["alt1", "alt2", "alt3"],
  #      "tags" => ["t1", "t3", "t2"],
  #      "description" => "desc",
  #      "categories" => [ <list of category URIs> ]
  #    }
  #  }
  def create
    params[:soap_service] ||= {} if is_api_request? # Sanitize for API Request
    wsdl_location = params[:soap_service][:wsdl_location] || ""
    wsdl_location = Addressable::URI.parse(wsdl_location).normalize.to_s unless wsdl_location.blank?
    
    if wsdl_location.blank?
      @error_message = "Please provide a valid WSDL URL"
      respond_to do |format|
        format.html { render :action => "new" }
        # TODO: implement format.xml  { render :xml => '', :status => 406 }
        format.json { error_to_back_or_home("Please provide a valid WSDL URL", false, 406) }
      end
    else
      @soap_service = SoapService.new(:wsdl_location => wsdl_location)
      success, data = @soap_service.populate
      
      # Check for a duplicate
      @existing_service = SoapService.check_duplicate(wsdl_location, data["endpoint"])
      
      if !@existing_service.nil?
        respond_to do |format|
          format.html { render :action => "new" }
          # TODO: implement format.xml  { render :xml => '', :status => :unprocessable_entity }
          format.json { render :json => @existing_service.to_json, :status => 403, :location => @existing_service }
        end
      else
        respond_to do |format|
          if success
            if is_api_request? # Sanitize for API Request
              category_ids = []
              
              params[:annotations] ||= {}
              params[:annotations][:categories] ||= []
              
              params[:annotations][:categories].compact.each { |cat| category_ids << BioCatalogue::Api.object_for_uri(cat.to_s).id if BioCatalogue::Api.object_for_uri(cat.to_s) }
              params[:annotations][:categories] = category_ids
            end


            success = @soap_service.submit_service(data["endpoint"], current_user, params[:annotations].clone)
            if success
              flash[:notice] = 'Service was successfully submitted.'
              format.html { redirect_to(@soap_service.service(true)) }
              # TODO: implement format.xml  { render :xml => @soap_service, :status => :created, :location => @soap_service }
              format.json { 
                render :json => { 
                  :success => { 
                    :message => "The SOAP Service '#{@soap_service.name}' has been successfully submitted.", 
                    :resource => service_url(@soap_service.service(true))
                  }
                }.to_json, 
                :status => :created,
                :location => service_url(@soap_service.service(true))
              }
            else
              flash.now[:error] = 'An error has occurred with the submission. Please <a href="/contact">contact us</a> to report this. Thank you.'
              format.html { render :action => "new" }
              # TODO: implement format.xml  { render :xml => '', :status => 500 }
              format.json { error_to_back_or_home("An error has occurred with the submission.", false, 500) }
            end
          else
            format.html { render :action => "new" }
            format.xml  { render :xml => @soap_service.errors, :status => :unprocessable_entity }
            format.json { 
              error_list = []
              @soap_service.errors.to_a.each { |e| error_list << e[1] }
              error_to_back_or_home(error_list, false, 500)
            }
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
        "If this problem persists, please <a href='/contact'>contact us</a>".html_safe
      
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
              @error_message_details = err_msgs.to_sentence.html_safe
            end
          else
            # Submit a job to run the service updater
            BioCatalogue::ServiceUpdater.submit_job_to_run_service_updater(@existing_service.id)
          end
        else
          @error_message = err_text
          @error_message_details = err_msgs.to_sentence.html_safe
        end
      rescue Exception => ex
        @error_message = err_text
        @error_message_details = ex.message
        BioCatalogue::Util.yell("Failed to load WSDL from URL - #{wsdl_location}.\nException: #{ex.message}.\nStack trace: #{ex.backtrace.join('\n')}".html_safe)
      end
    end
    respond_to do |format|
      format.html { render :action => "new" }
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
            if SoapService.first(:conditions => ["wsdl_location = ?", url])
              @soap_service = SoapService.first(:conditions => ["wsdl_location = ?", url])
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
      format.json { redirect_to(generate_include_filter_url(:ass, @soap_service.id, "annotations", :json)) }
    end
  end
  
  def operations
    respond_to do |format|
      format.html { disable_action }
      format.xml  # operations.xml.builder
      format.json { render :json => @soap_service.to_custom_json("operations") }
    end
  end
  
  def deployments
    respond_to do |format|
      format.html { disable_action }
      format.xml  # deployments.xml.builder
      format.json { render :json => @soap_service.to_custom_json("deployments") }
    end
  end
  
  def wsdl_locations
    @wsdl_locations = SoapService.all(:select => "wsdl_location").map { |s| s.wsdl_location }.uniq.compact
    respond_to do |format|
      format.html { disable_action }
      format.xml  # wsdl_locations.xml.builder
      format.json { render :json => BioCatalogue::Api::Json.wsdl_locations(@wsdl_locations).to_json }
    end
  end
  
  def latest_wsdl
    send_data(@soap_service.latest_wsdl_contents, :type => "text/xml", :disposition => 'inline')
  end
  
protected # ========================================
  
  def find_soap_service
    @soap_service = SoapService.find(params[:id])
  end
  
  def find_soap_services

    # Sorting
    
    order = 'soap_services.created_at DESC'
    order_field = nil
    order_direction = nil
    
    case @sort_by
      when 'created'
        order_field = "created_at"
    end
    
    case @sort_order
      when 'asc'
        order_direction = 'ASC'
      when 'desc'
        order_direction = "DESC"
    end
    
    unless order_field.blank? or order_direction.nil?
      order = "soap_services.#{order_field} #{order_direction}"
    end
    
    @soap_services = SoapService.paginate(:page => @page,
                                          :per_page => @per_page,
                                          :order => order)
  end

  def parse_sort_params
    sort_by_allowed = [ "created" ]
    @sort_by = if params[:sort_by] && sort_by_allowed.include?(params[:sort_by].downcase)
      params[:sort_by].downcase
    else
      "created"
    end
    
    sort_order_allowed = [ "asc", "desc" ]
    @sort_order = if params[:sort_order] && sort_order_allowed.include?(params[:sort_order].downcase)
      params[:sort_order].downcase
    else
      "desc"
    end
  end

end
