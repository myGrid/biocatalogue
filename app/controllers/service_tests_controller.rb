# BioCatalogue: app/controllers/service_tests_controller.rb
#
# Copyright (c) 2009-2010, University of Manchester, The European Bioinformatics
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details.

class ServiceTestsController < ApplicationController
  
  before_filter :disable_action, :only => [ :new, :edit, :update ]
  before_filter :disable_action_for_api, :except => [ :show, :create, :results, :index ]
  
  before_filter :find_service_test, :only => [ :show, :results, :enable, :disable, :destroy]
  
  # Only logged in users can add tests
  before_filter :login_or_oauth_required, :only => [ :create, :enable, :disable, :destroy, :index ]

  before_filter :authorise, :only => [ :enable, :disable, :destroy ]
  
  before_filter :authorise_for_disabled, :only => [ :show ]
  
  before_filter :authorise_for_destroy, :only => [ :destroy ]
  
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
        flash[:notice] = "<div class=\"flash_header\">Service test has been deactivated</div><div class=\"flash_body\">.</div>"
        format.html{redirect_to(service_url(@service_test.service, :id => @service_test.service.id, :anchor => "testscripts")) }
        Delayed::Job.enqueue(BioCatalogue::Jobs::ServiceTestDisableNotification.new(current_user, @service_test, 
                                                                                      MONITORING_STATUS_CHANGE_RECIPIENTS, base_host))
        format.xml { disable_action }
      else
        flash[:notice] = "<div class=\"flash_header\">Could not deactivate service test</div><div class=\"flash_body\">.</div>"
        format.html{redirect_to(service_url(@service_test.service, :id => @service_test.service.id, :anchor => "testscripts")) }
        format.xml { disable_action }
      end
    end
  end
  
  def enable

    respond_to do |format|
      if @service_test
        if @service_test.activate!
          flash[:notice] = "<div class=\"flash_header\">Service test has been activated</div><div class=\"flash_body\">.</div>"
          format.html{ redirect_to(service_url(@service_test.service, :id => @service_test.service.id, :anchor => "testscripts")) }
          format.xml { disable_action }
        else
          flash[:error] = "<div class=\"flash_header\">Could not activate service test</div><div class=\"flash_body\">.</div>"
          format.html{ redirect_to(service_url(@service_test.service, :id => @service_test.service.id, :anchor => "testscripts")) }
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
        flash[:notice] = "ServiceTest with id '#{@service_test.id}' has been deleted"
        format.html { redirect_to service_url(@service_test.service) }
        format.xml  { head :ok }
      else
        flash[:error] = "Failed to delete ServiceTest with id '#{@service_test.id}'"
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
      flash[:error] = "You are not allowed to perform this action!"
      redirect_to @service_test.service
    end
  end
  
  def authorise_for_disabled
    unless BioCatalogue::Auth.allow_user_to_curate_thing?(current_user, @service_test.service) || @service_test.enabled?
      flash[:error] = "Service test is disabled!"
      redirect_to @service_test.service
    end
  end
  
  def authorise_for_destroy
    if @service_test.test.is_a?(UrlMonitor)
      flash[:error] = "You are not allowed to perform this action!"
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
                              
    if request.xml_http_request?
      render :partial => "service_tests/listing", :locals => {:items => @service_tests }, :layout => false
    end
    
  end

end
