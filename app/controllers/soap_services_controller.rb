# BioCatalogue: app/controllers/soap_services_controller.rb
#
# Copyright (c) 2008, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details.


class SoapServicesController < ApplicationController
  
  before_filter :disable_action, :only => [ :index, :show, :edit, :update, :destroy, :bulk_new, :bulk_create ]
  
  before_filter :login_required, :except => [ :index, :show ]
  
  # GET /soap_services
  # GET /soap_services.xml
  def index
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
    params[:annotations] = { }

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
    params[:annotations] = { }
    
    wsdl_location = params[:wsdl_url] || ''
    wsdl_location = Addressable::URI.parse(wsdl_location).normalize.to_s unless wsdl_location.blank?
    
    if wsdl_location.blank?
      @error_message = "Please provide a valid WSDL URL"
    else
      @soap_service = SoapService.new(:wsdl_location => wsdl_location)
      
      err_text = "Failed to load the WSDL URL provided.<br/>" +
        "Please check that it points to a valid WSDL file.<br/>" +
        "If this problem persists, please <a href='/contact'>contact us</a>"
      
      begin
        
        @wsdl_info, err_msgs, wsdl_file = BioCatalogue::WSDLUtils::WSDLParser.parse(@soap_service.wsdl_location)
        #try the old parser if new on fails
        if @wsdl_info.blank?
          @wsdl_info, err_msgs, wsdl_file = BioCatalogue::WsdlParser.parse(@soap_service.wsdl_location)
        end
        # Check for a duplicate
        @existing_service = SoapService.check_duplicate(wsdl_location, @wsdl_info["end_point"])
        
        # Only continue we have valid wsdl_indo or if no duplicate was found
        if @wsdl_info and !@wsdl_info.blank?
          if @existing_service.nil?
            if err_msgs.empty?
              @error_message = nil
              
              # Try and find location of the service from the url of the WSDL.
              @wsdl_geo_location = BioCatalogue::Util.url_location_lookup(@soap_service.wsdl_location)
            else
              @error_message = err_text
            end
          end
        else
          @error_message = err_text
        end
      rescue Exception => ex
        @error_message = err_text
        logger.error("Failed to load WSDL from URL - #{wsdl_location}. Exception:")
        logger.error(ex.message)
        logger.error(ex.backtrace.join("\n"))
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
   
  
end
