class SoapServicesController < ApplicationController
  # GET /soap_services
  # GET /soap_services.xml
  def index
    @soap_services = SoapService.find(:all)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @soap_services }
    end
  end

  # GET /soap_services/1
  # GET /soap_services/1.xml
  def show
    @soap_service = SoapService.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @soap_service }
    end
  end

  # GET /soap_services/new
  # GET /soap_services/new.xml
  def new
    @soap_service = SoapService.new

    respond_to do |format|
      format.html # new.html.erb
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
    @soap_service = SoapService.new(params[:soap_service])
    params[:soap_service]['new_service_attributes'] = @soap_service.get_service_attributes(
                                                              params[:soap_service][:wsdl_location])
    @soap_service = SoapService.new(params[:soap_service])
    respond_to do |format|
      if @soap_service.save
        flash[:notice] = 'SoapService was successfully created.'
        format.html { redirect_to(@soap_service) }
        format.xml  { render :xml => @soap_service, :status => :created, :location => @soap_service }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @soap_service.errors, :status => :unprocessable_entity }
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
end
