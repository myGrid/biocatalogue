class ServicesController < ApplicationController
  # GET /services
  # GET /services.xml
  def index
    @services = Service.paginate(:page => params[:page], :order => 'created_at DESC')

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @services }
    end
  end

  # GET /services/1
  # GET /services/1.xml
  def show
    @service = Service.find(params[:id])
    
    @latest_version = @service.latest_version
    @latest_version_instance = @latest_version.service_versionified
    
    @all_service_version_instances = @service.all_service_version_instances
    @all_service_types = @service.all_service_types
    
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @service }
    end
  end

  # GET /services/new
  # GET /services/new.xml
  def new
    @service = Service.new
    
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @service }
    end
  end

  # GET /services/1/edit
  def edit
    @service = Service.find(params[:id])
  end

  # POST /services
  # POST /services.xml
  def create
    # Creation of a Service resource is not allowed. Must be created as part of the creation of a specific service type resource.
    flash[:error] = 'Select the type of service you would like to submit'
    respond_to do |format|
      format.html { redirect_to(new_service_url) }
      format.xml  { render :xml => '', :status => 406 }
    end
  end

  # PUT /services/1
  # PUT /services/1.xml
  def update
    @service = Service.find(params[:id])

    respond_to do |format|
      if @service.update_attributes(params[:service])
        flash[:notice] = 'Service was successfully updated.'
        format.html { redirect_to(@service) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @service.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /services/1
  # DELETE /services/1.xml
  def destroy
    @service = Service.find(params[:id])
    @service.destroy

    respond_to do |format|
      format.html { redirect_to(services_url) }
      format.xml  { head :ok }
    end
  end

  #render service registration depending on service
  #type selected by user
  def update_service_registration_form
    #@service = service_maker('SOAP').new 
    #change when REST/DAS services are available
    service_type = params[:service_type]
    @service = service_maker(service_type).new
    
    if service_type == 'SOAP'
      render :partial=> 'soap'
      #redirect_to :controller =>'soap_services',  :action => 'new'
    elsif service_type == 'REST'
      render :partial=> 'rest'
      #redirect_to :controller =>'rest_services',  :action => 'new'
    elsif service_type == 'DAS'
      render :partial=> 'das'
    elsif service_type == 'SOAPLAB-SERVER'
      render :partial=> 'soaplab_server'
      #redirect_to :controller =>'soaplab_servers',  :action => 'new'
    else
      render :partial => 'unknown_service_type'
    end
      
  end
  
  
  private 
  def service_maker(service_type)
    @services = {'SOAP' => SoapService,
                 'REST' => RestService,
                 'SOAPLAB-SERVER' => SoapService}
                 #'DAS'  => DasService}
    if @services.keys.include?(service_type)
      return @services[service_type]
    end
    return nil
  end
  
  
  
  
end
