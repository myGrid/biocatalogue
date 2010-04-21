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
  before_filter :login_required, :only => [ :create, :enable, :disable ]
  before_filter :authorise, :only => [ :enable, :disable ]
  
  def show
    respond_to do |format|
      format.html { disable_action }
      format.xml  # show.xml.builder
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
    end
  end
  
  def disable
    @test = @service_test.test
    
    respond_to do |format|
      if @test.update_attribute(:activated_at, nil)
        flash[:notice] = "Service test with id #{@service_test.id} has been deactivated."
        format.html{redirect_to @service_test.service }
        format.xml { disable_action }
      else
        flash[:error] = "Could not deactivate service test  with id #{@service_test.id} ."
        format.html{redirect_to @service_test.service }
        format.xml { disable_action }
      end
    end
  end
  
  def enable
    @test = @service_test.test
    
    respond_to do |format|
      if @test.update_attribute(:activated_at, Time.now)
        flash[:notice] = "Service test with id #{@service_test.id} has been activated."
        format.html{redirect_to @service_test.service }
        format.xml { disable_action }
      else
        flash[:error] = "Could not activate service test  with id #{@service_test.id} ."
        format.html{redirect_to @service_test.service }
        format.xml { disable_action }
      end
    end
  end
  
  
  protected
  
  def find_service_test
    @service_test = ServiceTest.find(params[:id])
  end
  
  def authorise
    unless current_user && current_user.is_admin?
      flash[:error] = "You are not allowed to perform this action! "
      redirect_to @service_test.service
      # error_to_back_or_home("You are not allowed to perform this action")
      # return false
    end
  end

end
