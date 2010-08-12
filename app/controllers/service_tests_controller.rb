# BioCatalogue: app/controllers/service_tests_controller.rb
#
# Copyright (c) 2009-2010, University of Manchester, The European Bioinformatics
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details.

class ServiceTestsController < ApplicationController
  
  before_filter :disable_action, :only => [ :index, :new, :edit, :update, :destroy ]
  before_filter :disable_action_for_api, :except => [ :show, :create, :results ]
  
  before_filter :find_service_test, :only => [ :show, :results, :enable, :disable ]
  
  # Only logged in users can add tests
  before_filter :login_or_oauth_required, :only => [ :create, :enable, :disable ]

  before_filter :authorise, :only => [ :enable, :disable ]

  if ENABLE_SSL && Rails.env.production?
    ssl_allowed :all
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
  
  
  protected
  
  def find_service_test
    @service_test = ServiceTest.find(params[:id])
  end
  
  #TODO investigate why "error_to_back_or_home" is causing multiple redirect errors
  def authorise
    unless logged_in? && BioCatalogue::Auth.allow_user_to_curate_thing?(current_user, @service_test.service)
      flash[:error] = "You are not allowed to perform this action! "
      redirect_to @service_test.service
    end
  end

end
