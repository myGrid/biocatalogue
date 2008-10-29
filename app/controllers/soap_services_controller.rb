require 'wsdl_parser'

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
    # Check for a duplicate
    @existing_soap_service = SoapService.find(:first, :conditions => ["wsdl_location = ?", wsdl_url])
    
    if !@existing_soap_service.nil?
      respond_to do |format|
        format.html { render :action => "new" }
        format.xml  { render :xml => '', :status => 406 }
      end
    else
      @soap_service = SoapService.new(params[:soap_service])
      @soap_service.populate
      
      respond_to do |format|
        if @soap_service.save
          # TODO: store the extra information provided in the form, as Annotations.
          
          flash[:notice] = 'SoapService was successfully created.'
          format.html { redirect_to(@soap_service.service) }
          
          # TODO: should this return the top level Service resource or SoapService? 
          format.xml  { render :xml => @soap_service, :status => :created, :location => @soap_service }
        else
          format.html { render :action => "new" }
          format.xml  { render :xml => @soap_service.errors, :status => :unprocessable_entity }
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
    wsdl_url = params[:wsdl_url]
    wsdl_url = wsdl_url.strip unless wsdl_url.blank?
    
    if wsdl_url.blank?
      @error_message = "Please provide a valid WSDL URL"
    else
      # Check for a duplicate
      @existing_soap_service = SoapService.find(:first, :conditions => ["wsdl_location = ?", wsdl_url])
      
      # Only continue if no duplicate was found
      if @existing_soap_service.nil?
        @soap_service = SoapService.new(:wsdl_location => wsdl_url)
        
        begin
          #@wsdl_info = @soap_service.get_service_attributes
          @wsdl_info, err_msgs, wsdl_file = BioCatalogue::WsdlParser.parse(@soap_service.wsdl_location)
          
          if err_msgs.empty?
            @error_message = nil
          else
            @error_message = "Error messages: #{err_msgs.to_sentence}."
          end
        rescue Exception => ex
          @error_message = "Failed to load the WSDL location provided."
          logger.info("ERROR: failed to load WSDL from location - #{wsdl_url}. Exception:")
          logger.info(ex)
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
  
end
