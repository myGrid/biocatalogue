class WebServicesController < ApplicationController
  # GET /web_services
  # GET /web_services.xml
  def index
    @web_services = WebService.find(:all)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @web_services }
    end
  end

  # GET /web_services/1
  # GET /web_services/1.xml
  def show
    @web_service = WebService.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @web_service }
    end
  end

  # GET /web_services/new
  # GET /web_services/new.xml
  def new
    @service_types = ServiceType.find(:all)
    @web_service = WebService.new
    #@soap_service = SoapService.new
    #@soap_service = service_maker("SOAP").new
    #@soap_service = service_maker(params[:service_type]).new
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @web_service }
    end
  end

  # GET /web_services/1/edit
  def edit
    @web_service = WebService.find(params[:id])
  end

  # POST /web_services
  # POST /web_services.xml
  def create
    @web_service      = WebService.new(params[:web_service])
    @service_instance = service_maker(params[:web_service][:service_type]).new(params[:service])
    @operations       = @service_instance.get_operations(params[:service][:wsdl_location])
    @service_instance.get_outputs(@operations)
    
    #these saves should be transactional!!
    respond_to do |format|
      if @web_service.save
        @service_instance.web_service_id = @web_service.id
        if @service_instance.save 
          @service_instance.save_operations(@operations,@service_instance)
        end
        flash[:notice] = 'WebService was successfully created.'
        #format.html { redirect_to(@web_service) }
        format.html { redirect_to(@service_instance) }
        format.xml  { render :xml => @web_service, :status => :created, :location => @web_service }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @web_service.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /web_services/1
  # PUT /web_services/1.xml
  def update
    @web_service = WebService.find(params[:id])

    respond_to do |format|
      if @web_service.update_attributes(params[:web_service])
        flash[:notice] = 'WebService was successfully updated.'
        format.html { redirect_to(@web_service) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @web_service.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /web_services/1
  # DELETE /web_services/1.xml
  def destroy
    @web_service = WebService.find(params[:id])
    @web_service.destroy

    respond_to do |format|
      format.html { redirect_to(web_services_url) }
      format.xml  { head :ok }
    end
  end

  #render service registration depending on service
  #type selected by user
  def update_service_registration_form
    @service = service_maker('SOAP').new 
    #change when REST/DAS services are available
    service_type = params[:service_type]
    #@service = service_maker(service_type).new
    
    if service_type == 'SOAP'
      render :partial=> 'soap'
    elsif service_type == 'REST'
      render :partial=> 'rest'
    elsif service_type == 'DAS'
      render :partial=> 'das'
    else
      render :partial => 'unknown_service_type'
    end
      
  end
  
  private 
  def service_maker(service_type)
    @services = {'SOAP' => SoapService}
                 #'REST' => RestService,
                 #'DAS'  => DasService}
    @services[service_type]
  end
  
  
end
