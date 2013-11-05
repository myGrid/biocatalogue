# BioCatalogue: app/controllers/service_tests_controller.rb
#
# Copyright (c) 2009-2010, University of Manchester, The European Bioinformatics
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details.

class ServiceTestsController < ApplicationController
  
  before_filter :disable_action, :only => [ :new, :edit, :update ]
  before_filter :disable_action_for_api, :except => [ :show, :create, :results, :index ]
  
  before_filter :find_service_test, :only => [ :show, :results, :enable, :disable, :destroy, :edit_monitoring_endpoint_by_popup, :update_monitoring_endpoint ]
  
  before_filter :find_service, :only => [ :new_url_monitor_popup, :create_monitoring_endpoint ]

  # Only logged in users can add tests
  before_filter :login_or_oauth_required, :only => [ :create, :enable, :disable, :destroy, :index, :new_popup, :create_monitoring_endpoint, :edit_monitoring_endpoint_by_popup, :update_monitoring_endpoint ]

  before_filter :authorise, :only => [ :enable, :disable, :destroy, :edit_monitoring_endpoint_by_popup, :update_monitoring_endpoint ]
  
  before_filter :authorise_for_disabled, :only => [ :show ]
  
  before_filter :authorise_for_destroy, :only => [ :destroy ]

  before_filter :authorise_for_create, :only => [ :new_url_monitor_popup, :create_monitoring_endpoint ]
  
  before_filter :parse_sort_params, :only => [ :index ]
  
  before_filter :find_service_tests, :only => [ :index ]
  
  
  def index
    respond_to do |format|
      format.html # index.html.erb
      format.xml  # index.xml.builder
      format.atom # index.atom.builder
    end
  end
  
  def show
    respond_to do |format|
      format.html # show.html.erb
      format.xml  # show.xml.builder
      format.json { render :json => @service_test.to_json }
    end
  end

  def new_url_monitor_popup    
    respond_to do |format|
      format.js { render :layout => false }
    end
  end
  
  def edit_monitoring_endpoint_by_popup
    respond_to do |format|
      format.js { render :layout => false }
    end
  end
  
  def update_monitoring_endpoint
    error = nil
    
    error = "This service test cannot be updated because it is not a custom endpoint monitor.".html_safe unless @service_test.is_custom_endpoint_monitor?
    monitoring_endpoint_annotation = @service_test.test.parent
    
    # sanitize user input
    if error.nil?
      # sanitize the user provided endpoint
      new_endpoint = params[:new_monitoring_endpoint] || ""
      new_endpoint.strip!
      
      error = validate_endpoint_returning_error(@service, new_endpoint)
      
      if error.nil?
        existing_endpoint = monitoring_endpoint_annotation.value_content
        error = "The service test could not be updated as the new endpoint was the same as the existing one.".html_safe if existing_endpoint.downcase == new_endpoint.downcase
      end 
    end
    
    # update url monitor and cleanup
    if error.nil?
      begin
        ServiceTest.transaction do          
          # update url monitor
          monitoring_endpoint_annotation.value.ann_content = new_endpoint
          monitoring_endpoint_annotation.save!
          
          @service_test.updated_at = Time.now
          @service_test.save!
        end
      rescue Exception => ex
        error = "Failed to update monitoring endpoint.".html_safe
        
        logger.error("Failed to update monitoring endpoint. Exception:")
        logger.error(ex.message)
        logger.error(ex.backtrace.join("\n"))
      end
    end
    
    respond_to do |format|      
      if error.nil?
        flash[:notice] = "The monitoring endpoint for service '#{BioCatalogue::Util.display_name(@service)}' has been updated".html_safe
      else
        flash[:error] = error
      end
      
      redirect_url = service_test_url(@service_test)
      format.html { redirect_to redirect_url }
    end
  end
  
  def create_monitoring_endpoint
    error = nil
    
    error = "The service already contains a custom endpoint to monitor.".html_safe unless @service.has_capacity_for_new_monitoring_endpoint?
    
    # sanitize user input
    if error.nil?
      # sanitize the user provided endpoint
      monitoring_endpoint = params[:monitoring_endpoint] || ""
      monitoring_endpoint.strip!
      
      error = validate_endpoint_returning_error(@service, monitoring_endpoint) 
    end
    
    # create url monitor and service test    
    if error.nil?
      begin
        ServiceTest.transaction do
          # create monitoring_endpoint annotations
          anns = @service.create_annotations({"monitoring_endpoint" => monitoring_endpoint}, current_user)
          
          # use annotation to create url_monitor
          ann = anns.first
          
          mon = UrlMonitor.new(:parent_id => ann.id, :parent_type => ann.class.name, :property => "value")
          @service_test = ServiceTest.new(:service_id => @service.id, :test_type => mon.class.name, :activated_at => Time.now )
          mon.service_test = @service_test

          mon.save!
          @service_test.save!
        end
      rescue Exception => ex
        error = "Failed to create monitoring endpoint".html_safe
        
        logger.error("Failed to create monitoring endpoint: #{monitoring_endpoint}. Exception:")
        logger.error(ex.message)
        logger.error(ex.backtrace.join("\n"))
      end
    end

    respond_to do |format|      
      if error.nil?
        redirect_url = service_test_url(@service_test)
        flash[:notice] = "A new monitoring endpoint has been created for service '#{BioCatalogue::Util.display_name(@service)}'".html_safe
      else
        redirect_url = service_url(@service, :anchor => "monitoring")
        flash[:error] = error
      end
      
      format.html { redirect_to redirect_url }
    end  
  end
  
  # POST /service_tests
  def create
    # FIXME & TODO: need to redo this code for the submission of service tests via XML API
    
    testable_type = params[:service_test][:testable_type]
    testable_id   = params[:service_test][:testable_id]
    
    # Get the object associated with this test
    testable = ServiceTest.find_testable(testable_type, testable_id)
    logger.info("got testable #{testable.class.to_s}")
    
    #create a test with user supplied content
    #note : test_data (blob) is stored in the content_blobs table
    service_test = ServiceTest.new(params[:service_test])
    
    #record who uploaded this test
    service_test.user_id = session[:user_id]
    
    #add the test
    testable.service_tests << service_test
    
    redirect_to testable
  end
  
  def results
    respond_to do |format|
      format.html { disable_action }
      format.xml { redirect_to(test_results_url(:service_test_id => @service_test.id, :format => :xml)) }
      format.json { redirect_to(test_results_url(:service_test_id => @service_test.id, :format => :json)) }
    end
  end
  
  def disable

    respond_to do |format|
      if @service_test.deactivate!
        flash[:notice] = "<div class=\"flash_header\">Service test has been deactivated</div><div class=\"flash_body\">.</div>".html_safe
        format.html{redirect_to(service_test_url(@service_test)) }
        Delayed::Job.enqueue(BioCatalogue::Jobs::ServiceTestDisableNotification.new(current_user, @service_test, 
                                                                                      MONITORING_STATUS_CHANGE_RECIPIENTS, base_host))
        format.xml { disable_action }
      else
        flash[:notice] = "<div class=\"flash_header\">Could not deactivate service test</div><div class=\"flash_body\">.</div>".html_safe
        format.html{redirect_to(service_test_url(@service_test)) }
        format.xml { disable_action }
      end
    end
  end
  
  def enable

    respond_to do |format|
      if @service_test
        if @service_test.activate!
          flash[:notice] = "<div class=\"flash_header\">Service test has been activated</div><div class=\"flash_body\">.</div>".html_safe
          format.html{redirect_to(service_test_url(@service_test)) }
          format.xml { disable_action }
        else
          flash[:error] = "<div class=\"flash_header\">Could not activate service test</div><div class=\"flash_body\">.</div>".html_safe
          format.html{redirect_to(service_test_url(@service_test)) }
          format.xml { disable_action }
        end
      end
    end
  end
  
  # DELETE /service_test/1
  # DELETE /service_service/1.xml
  def destroy
    respond_to do |format|
      if @service_test.destroy
        flash[:notice] = "ServiceTest with id '#{@service_test.id}' has been deleted".html_safe
        format.html { redirect_to service_url(@service_test.service) }
        format.xml  { head :ok }
      else
        flash[:error] = "Failed to delete ServiceTest with id '#{@service_test.id}'".html_safe
        format.html { redirect_to service_url(@service_test.service) }
      end
    end
  end
  
  protected
  
  def find_service_test
    @service_test = ServiceTest.find(params[:id])
    @service      = @service_test.service
  end
  
  def authorise
    unless BioCatalogue::Auth.allow_user_to_curate_thing?(current_user, @service_test.service)
      flash[:error] = "You are not allowed to perform this action!".html_safe
      redirect_to @service_test.service
    end
  end
  
  def authorise_for_disabled
    return if is_api_request?
    
    unless BioCatalogue::Auth.allow_user_to_curate_thing?(current_user, @service_test.service) || @service_test.enabled?
      flash[:error] = "Service test is disabled!".html_safe
      redirect_to @service_test.service
    end
  end
  
  def authorise_for_create
    unless BioCatalogue::Auth.allow_user_to_curate_thing?(current_user, @service)
      flash[:error] = "You are not allowed to perform this action!".html_safe
      redirect_to @service
    end
  end

  def authorise_for_destroy
    if @service_test.test.is_a?(UrlMonitor)
      flash[:error] = "You are not allowed to perform this action!".html_safe
      redirect_to @service_test.service
    end
  end
  
  
  def parse_sort_params
    sort_by_allowed = [ "created", "availability", "bytype", "status" ]
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
  
  
  def find_service_tests
    
    conditions  = 'activated_at IS NOT NULL'

    case @sort_by
      when 'created'
        order_field = "created_at"
      when 'availability'
        order_field = 'success_rate'
      when 'bytype'
        order_field = 'test_type'
      when 'status'
        order_field = 'cached_status'
    end
    
    case @sort_order
      when 'asc'
        order_direction = 'ASC'
      when 'desc'
        order_direction = "DESC"
    end
    
    unless order_field.blank? or order_direction.nil?
      order = "service_tests.#{order_field} #{order_direction}"
    end
    
       
    @service_tests = ServiceTest.paginate(  :page => @page,
                                              :per_page => @per_page, 
                                              :conditions => conditions,
                                              :order => order)
                              
    if request.xml_http_request? &&  ENABLE_TEST_SCRIPTS == true
      render "service_tests/_listing", :locals => {:items => @service_tests }, :layout => false
    end
    
  end

  
  def find_service
    @service = Service.find(params[:service_id])
  end
  
  def validate_endpoint_returning_error(service, monitoring_endpoint)
    error = nil
    
    begin
      # validate the provided endpoint
      URI.parse(monitoring_endpoint)
    rescue Exception => ex
      error = "The URL provided was invalid and could not be used".html_safe
      
      logger.error("Failed to validate monitoring endpoint: #{monitoring_endpoint}. Exception:")
      logger.error(ex.message)
      logger.error(ex.backtrace.join("\n"))
    end

    # check that user provided monitoring_endpoint contains base endpoint
    if error.nil?
      base_url = service.service_deployments.first.endpoint
      
      if base_url.downcase == monitoring_endpoint.downcase
        error = "The endpoint to monitor cannot be the same as the base URL.".html_safe
      elsif !monitoring_endpoint.downcase.starts_with?(base_url.downcase)
        error = "The endpoint to monitor should start with the base URL of the service.".html_safe
      end
    end
    
    return error
  end
  
end
