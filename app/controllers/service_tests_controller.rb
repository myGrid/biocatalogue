class ServiceTestsController < ApplicationController
  
  #only logged users can add tests
  before_filter :login_required, :only => [ :add_test]
  
  
  # GET /soap_services/1
  # GET /soap_services/1.xml
  def show
    @service_test = ServiceTest.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @service_test }
    end
  end
  
  def add_test
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

end
