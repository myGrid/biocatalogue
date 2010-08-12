# BioCatalogue: app/controllers/test_results_controller.rb
#
# Copyright (c) 2008, University of Manchester, The European Bioinformatics
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details.

class TestResultsController < ApplicationController
  
  before_filter :disable_action, :only => [ :new, :edit, :update, :destroy ]
  before_filter :disable_action_for_api, :except => [ :index, :show, :create ]
  
  before_filter :parse_sort_params, :only => [ :index ]
  
  before_filter :find_test_results, :only => [ :index ]
  
  before_filter :find_test_result, :only => [ :show ]
  
  def index
    respond_to do |format|
      format.html { disable_action }
      format.xml # index.xml.builder
      format.json { render :json => BioCatalogue::Api::Json.index("test_results", json_api_params, @test_results, false).to_json }
    end
  end
  
  def show
    respond_to do |format|
      format.html { disable_action }
      format.xml  # show.xml.builder
      format.json { render :json => @test_result.to_json }
    end
  end

  before_filter :login_or_oauth_required, :only => [ :create ]

  # POST /test_results
  def create
    # TODO: implement code for the submission of test_results via XML API
    @test_result = TestResult.new(params[:test_result])
    
    # FIXME: implement this following the API pattern
    respond_to do |format|
      if @test_result.save
        flash[:notice] = 'TestResult was successfully created.'
        #format.html { redirect_to(@test_result.service_test.service) }
        format.xml  { render :xml => @test_result.service_test.service, :status => :created, :location => @test_result.service_test.service }
      else
        #format.html { render :action => "new" }
        format.xml  { render :xml => @test_result.errors, :status => :unprocessable_entity }
      end
    end
  end
  
  protected
  
  def parse_sort_params
    sort_by_allowed = [ "created" ]
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
  
  def find_test_results
    
    # Sorting
    
    order = 'test_results.created_at DESC'
    order_field = nil
    order_direction = nil
    
    case @sort_by
      when 'created'
        order_field = "created_at"
    end
    
    case @sort_order
      when 'asc'
        order_direction = 'ASC'
      when 'desc'
        order_direction = "DESC"
    end
    
    unless order_field.blank? or order_direction.nil?
      order = "test_results.#{order_field} #{order_direction}"
    end
    
    # Check if a specific Service Test has been asked for
    @service_test = params[:service_test_id].blank? ? nil : ServiceTest.find(params[:service_test_id])
    conditions = if @service_test
      { :service_test_id => @service_test.id }
    else
      { }
    end
    
    @test_results = TestResult.paginate(:page => @page,
                                        :per_page => @per_page,
                                        :order => order,
                                        :conditions => conditions)
  end
  
  def find_test_result
    @test_result = TestResult.find(params[:id])
  end
  
end
