class SoapServicesController < ApplicationController
  before_filter :login_required, :only => [:new, :create, :update, :destroy]
  
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
    #params[:soap_service]['new_service_attributes'] = @soap_service.get_service_attributes(
    #                                                          params[:soap_service][:wsdl_location])
    #@soap_service = SoapService.new(params[:soap_service])
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
    
    
    def bulk_new
      @soap_service = SoapService.new

      respond_to do |format|
        format.html # new.html.erb
        format.xml  { render :xml => @soap_service }
      end
    end
    
    def bulk_create
      @soap_service = SoapService.new(params[:soap_service])
      @urls = []
      params[:bulk_submit].each { |line|
      urls << line.strip if line =~ /http:/}
      @urls.each do |url|
        params[:soap_service][:wsdl_location] = url
        create
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
