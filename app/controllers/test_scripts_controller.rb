# BioCatalogue: app/controllers/test_scripts_controller.rb
#
# Copyright (c) 2009, University of Manchester, The European Bioinformatics
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details.

class TestScriptsController < ApplicationController
  
  before_filter :disable_action_for_api
  
  before_filter :login_or_oauth_required, :only => [ :create ]
  before_filter :authorise_on_service, :only => [ :create ]
  before_filter :authorise_on_script, :only => [ :destroy ]
  
  # POST /test_scripts
  def create
    # FIXME & TODO: need to redo this code - need's to handle both creation of test script 
    # from an HTML web form and (possibly) from the XML REST API. TBD

    #record who uploaded this test
    params[:test_script][:submitter_id] = current_user.id

    #create a test with user supplied content
    #note : test_data (blob) is stored in the content_blobs table
    @test_script = TestScript.new(params[:test_script])
    @service_test = ServiceTest.new(:service_id => params[:testable_id],
                    :test => @test_script,
                    :activated_at => Time.now)

    respond_to do |format|
      if @service_test.save
        flash[:notice] = 'Test Script was successfully created. '
        format.html { redirect_to(service_url(@service, :id => @service.id, :anchor => "monitoring"))}
        format.xml  { render :xml => @test_script, :status => :created, :location => @test_script }
      else
        flash[:error] = 'There were problems submitting this test script! '
        format.html { render :partial => "shared/service_test",
                                        :layout =>'application',  :locals => {:service => @service,
                                                                              :test_script => @test_script } }
        format.xml  { render :xml => @test_script.errors, :status => :unprocessable_entity }
      end
    end
    #redirect_to testable
  end
  
  # DELETE /test_scripts/1
  # DELETE /test_scripts/1.xml
  def destroy
    respond_to do |format|
      if @test_script.destroy
        flash[:notice] = "TestScript '#{@test_script.name}' has been deleted"
        format.html { redirect_to @service_url }
        format.xml  { head :ok }
      else
        flash[:error] = "Failed to delete test script '#{@test_script.name}'"
        format.html { redirect_to(service_url(service.id, :anchor => "monitoring")) }
      end
    end
  end
  
  def download
    test = TestScript.find(params[:id])
    send_data(test.content_blob.data, :filename => test.filename, :type => test.content_type)
  end
  
  def authorise_on_script
    unless BioCatalogue::Auth.allow_user_to_curate_thing?(current_user, @test_script)
      error_to_back_or_home("You are not allowed to perform this action")
      return false
    end
    
    return true
  end
  
  def authorise_on_service
    @service = Service.find(params[:testable_id])
    unless BioCatalogue::Auth.allow_user_to_curate_thing?(current_user, @service)
      error_to_back_or_home("You are not allowed to perform this action")
      return false
    end
    
    return true
  end

end
