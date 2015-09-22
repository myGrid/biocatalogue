# BioCatalogue: app/controllers/services_controller.rb
#
# Copyright (c) 2009-2010, University of Manchester, The European Bioinformatics
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details.

class ServicesController < ApplicationController

  before_filter :disable_action, :only => [ :edit, :update ]
  before_filter :disable_action_for_api, :except => [ :index, :show, :filters, :summary, :annotations, :deployments, :variants, :monitoring, :activity, :filtered_index, :favourite, :unfavourite, :bmb ]

  before_filter :login_or_oauth_required, :only => [ :destroy, :check_updates, :archive, :unarchive, :favourite, :unfavourite ]

  before_filter :parse_filtered_index_params, :only => :filtered_index

  before_filter :parse_current_filters, :only => [ :index, :filtered_index, :filters ]

  before_filter :parse_sort_params, :only => [ :index, :filtered_index ]

  before_filter :find_services, :only => [ :index, :filtered_index ]

  before_filter :find_service, :only => [ :show, :service_endpoint, :edit, :update, :destroy, :categorise, :summary, :annotations, :deployments, :variants, :monitoring, :check_updates, :archive, :unarchive, :activity, :favourite, :unfavourite, :examples, :example_data, :example_scripts, :example_workflows ]

  before_filter :find_favourite, :only => [ :favourite, :unfavourite ]

  before_filter :authorise, :only => [ :destroy, :check_updates, :archive, :unarchive, :favourite, :unfavourite ]

  before_filter :check_if_user_wants_to_categorise, :only => [ :show ]

  before_filter :setup_for_index_feed, :only => [ :index ]

  before_filter :setup_for_activity_feed, :only => [ :activity ]

  before_filter :set_page_title_suffix, :only => [ :index ]

  before_filter :set_listing_type_local, :only => [ :index ]

  before_filter :show_page_variables, :only => [:monitoring, :show, :service_endpoint, :activity, :examples, :example_data, :example_scripts, :example_workflows]

  set_tab :scripts, :example_tab, :only => %w(example_scripts)
  set_tab :data, :example_tab, :only => %w(example_data examples)
  set_tab :workflows, :example_tab, :only => %w(example_workflows)
  set_tab :examples, :service, :only => %w(examples example_workflows example_data example_scripts)
  before_filter :examples, :only => %w(example_scripts example_data example_workflows)

  set_tab :overview, :service, :only => %w(show)
  set_tab :monitoring, :service, :only => %w(monitoring)
  set_tab :history, :service, :only => %w(activity)
  set_tab :service_endpoint, :service, :only => %w(service_endpoint)
  before_filter :show, :only => %w(overview examples history)

  def example_scripts ;     end
  def example_workflows ;  end
  def example_data ;       end


  # GET /services
  # GET /services.xml
  def index
    @per_page_options = %w{ 21 51 99 }
    respond_to do |format|
      format.html # index.html.erb
      format.xml  # index.xml.builder
      format.atom # index.atom.builder
      format.json { render :json => BioCatalogue::Api::Json.index("services", json_api_params, @services).to_json }
      format.bljson { render :json => BioCatalogue::Api::Bljson.index("services", @services).to_json }
    end
  end

  # POST /filtered_index
  # Example Input (differs based on available filters):
  #
  # {
  #   :filters => {
  #     :p => [ 67, 23 ],
  #     :tag => [ "database" ],
  #     :c => ["Austria", "south Africa"]
  #   }
  # }
  def filtered_index
    index
  end

  # GET /services/1
  # GET /services/1.xml
  def show
    @latest_version = @service.latest_version
    @latest_version_instance = @latest_version.service_versionified
    @latest_deployment = @service[:latest_deployment]
    @wms_layer_count = WmsServiceNode.find_by_wms_service_id(@service[:id])
    if !@wms_layer_count.nil?
      @wms_layer_count = @wms_layer_count[:layer_count]
    end

    @all_service_version_instances = @service.service_version_instances
    @all_service_types = @service.service_types

    @soaplab_server = @service.soaplab_server

    @pending_responsibility_requests = @service.pending_responsibility_requests
    unless is_api_request?
      @service_tests = @service.service_tests
      @test_script_service_tests  = @service.service_tests_by_type("TestScript")
      @url_monitor_service_tests  = @service.service_tests_by_type("UrlMonitor")
    end
    if @latest_version_instance.is_a?(RestService)
      @grouped_rest_methods = @latest_version_instance.group_all_rest_methods_from_rest_resources
    end
    @test = "kjhbkb"
    respond_to do |format|
      format.html # show.html.erb
      format.xml  # show.xml.builder
      format.json { render :json => @service.to_json }
    end
  end

  # GET /services/new
  # GET /services/new.xml
  def new
    @service = Service.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml
    end
  end

  # GET /services/1/edit
  def edit
  end

  # POST /services
  # POST /services.xml
  def create
    # Creation of a Service resource is not allowed. Must be created as part of the creation of a specific service type resource.
    flash[:error] = 'Select the type of service you would like to submit first'
    respond_to do |format|
      format.html { redirect_to(new_service_url) }
      format.xml  { render :xml => '', :status => 404 }
    end
  end

  # PUT /services/1
  # PUT /services/1.xml
  def update
    respond_to do |format|
      if @service.update_attributes(params[:service])
        flash[:notice] = 'Service was successfully updated.'
        format.html { redirect_to(@service) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @service.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /services/1
  # DELETE /services/1.xml
  def destroy
    respond_to do |format|
      if @service.destroy

        # check if it is a wms service
        if !WmsServiceNode.find_by_wms_service_id(params[:id]).nil?
          # delete
          delete_wms_service(params[:id])
        end

        flash[:notice] = "Service '#{@service.name}' has been deleted"
        format.html { redirect_to services_url }
        format.xml  { head :ok }
      else
        flash[:error] = "Failed to delete service '#{@service.name}'"
        format.html { redirect_to service_url(@service) }
      end
    end
  end





  def delete_wms_service(id)

    # delete keywords
    WmsKeywordlist.where(wms_service_node_id: id).find_each do |keyword|
      keyword.delete
    end

    # delete contact information
    WmsContactInformation.where(wms_service_node_id: id).find_each do |contactinfo|
      contactinfo.delete
    end

    # delete exception formats
    WmsExceptionFormat.where(wms_service_id: id).find_each do |exception|
      exception.delete
    end

    # delete getcapabiliteis_formats
    WmsGetcapabilitiesFormat.where(wms_service_id_id: id).find_each do |format|
      format.delete
    end

    # delete get_online_resources
    WmsGetcapabilitiesGetOnlineresource.where(wms_service_id: id).find_each do |geton|
      geton.delete
    end

    # delete post_online_resources
    WmsGetcapabilitiesPostOnlineresource.where(wms_service_id: id).find_each do |poston|
      poston.delete
    end

    # delete online_resources
    WmsOnlineResource.where(wms_service_node_id: id).find_each do |resource|
      resource.delete
    end

    # delete getmap_formats
    WmsGetmapFormat.where(wms_service_id: id).find_each do |getmapformat|
      getmapformat.delete
    end

    # delete getmap_get_online
    WmsGetmapGetOnlineresource.where(wms_service_id: id).find_each do |getonline|
      getonline.delete
    end

    # delete getmap_post_online
    WmsGetmapPostOnlineresource.where(wms_service_id: id).find_each do |postonline|
      postonline.delete
    end

    # find associated layers and delete
    WmsLayer.where(wms_service_id: id).find_each do |layer|
      delete_layer(layer)
    end

    # delete service itself
    WmsServiceNode.where(wms_service_id: id).find_each do |servicenode|
      servicenode.delete
    end

  end

  def delete_layer(layer)
=begin

    # delete keywords
    WmsLayer.where(wms_layer_id: layer.id).find_each do |keyword|
      keyword.delete
    end
=end

    # delete boundingboxes
    WmsLayerBoundingbox.where(wms_layer_id: layer.id).find_each do |bbox|
      bbox.delete
    end

    # delete crs
    WmsLayerCrs.where(wms_layer_id: layer.id).find_each do |crs|
      crs.delete
    end

    # delete styles
=begin
    WmsLayerStyle.where(wms_layer_id: layer.id).find_each do |style|
      style.delete
    end
=end

    # find child layers and
    # recursively call this method
    WmsLayer.where(wms_layer_id: layer.id).find_each do |childlayer|
      delete_layer(childlayer)
    end

    # delete layer itself
    layer.delete

  end






  def categorise
    categories = [ ]
    anns = [ ]

    categories = params[:categories] if params.has_key?(:categories)

    unless categories.empty?
      anns = @service.create_annotations({ "category" => categories.split(',').compact.map{|x| x.strip}.reject{|x| x == ""} }, current_user)
    end

    respond_to do |format|
      flash[:notice] = if anns.empty?
        "No new categories specified"
      else
        "Categories successfully added"
      end
      format.html { redirect_to(service_url(@service)) }
    end
  end

  def filters
    if is_api_request?
      get_filter_groups
    end

    respond_to do |format|
      format.html # filters.html.erb
      format.xml # filters.xml.builder
      format.json { render :json => BioCatalogue::Api::Json.filter_groups(@filter_groups).to_json }
      format.js { render :layout => false }
    end
  end

  def summary
    respond_to do |format|
      format.html { disable_action }
      format.xml # summary.xml.builder
      format.json { render :json => @service.to_custom_json("summary") }
    end
  end

  def annotations
    respond_to do |format|
      format.html { disable_action }
      format.xml { redirect_to(generate_include_filter_url(:as, @service.id, "annotations", :xml)) }
      format.json { redirect_to(generate_include_filter_url(:as, @service.id, "annotations", :json)) }
    end
  end

  def deployments
    respond_to do |format|
      format.html { disable_action }
      format.xml # deployments.xml.builder
      format.json { render :json => @service.to_custom_json("deployments") }
    end
  end

  def variants
    respond_to do |format|
      format.html { disable_action }
      format.xml # versions.xml.builder
      format.json { render :json => @service.to_custom_json("variants") }
    end
  end

  def monitoring
    respond_to do |format|
      format.xml  # monitoring.xml.builder
      format.html { render 'services/show'}
    end
  end

  def check_updates
    # Submit a job to run the service updater
    BioCatalogue::ServiceUpdater.submit_job_to_run_service_updater(@service.id)

    flash[:notice] = "The service updater has been scheduled to run. Any new updates found will be shown in the 'News' tab."

    respond_to do |format|
      format.html { redirect_to @service }
    end
  end

  def archive
    @service.archive!
    respond_to do |format|
      flash[:notice] = "This service has been archived"
      format.html { redirect_to @service }
      format.xml  { head :ok }
    end
  end

  def unarchive
    @service.unarchive!
    respond_to do |format|
      flash[:notice] = "This service has been unarchived"
      format.html { redirect_to @service }
      format.xml  { head :ok }
    end
  end

  def activity
    respond_to do |format|
      format.html { render 'services/show'} # activity.html.erb
      format.atom  # activity.atom.builder
      format.js { render :layout => false }
    end
  end

  def service_endpoint

    # get service node, if wms
    servicenode = WmsServiceNode.find_by_wms_service_id(params[:id])
    @table = ""
    if !servicenode.nil?
      # get access constraints
      if !servicenode[:access_constraints].nil? and !servicenode[:access_constraints].eql?("")
        @table = @table + "<b>Access constraints for this service :</b><br />" + servicenode[:access_constraints].to_s + "<br /><br />"
      end
      # get fee information
      if !servicenode[:fees].nil? and !servicenode[:fees].eql?("")
        @table = @table + "<b>Fees :</b><br />" + servicenode[:fees].to_s + "<br /><br />"
      end

      # get contact information
      puts servicenode.id
      contact = WmsContactInformation.find_by_wms_service_node_id(servicenode.id)
      if !contact.nil?
        if !contact[:contact_person].nil? and !contact[:contact_person].eql?("")
          @table = @table + "<b>Contact person :</b><br /><br />" + contact[:contact_person].to_s + "<br /><br />"
        end

        if !contact[:contact_organization].nil? and !contact[:contact_organization].eql?("")
          @table = @table + "<b>Contact organization :</b><br /><br />" + contact[:contact_organization].to_s + "<br /><br />"
        end

        if !contact[:contact_position].nil? and !contact[:contact_position].eql?("")
          @table = @table + "<b>Contact position :</b><br /><br />" + contact[:contact_position].to_s + "<br /><br />"
        end

        if !contact[:address_type].nil? and !contact[:address_type].eql?("")
          @table = @table + "<b>Address type :</b><br /><br />" + contact[:address_type].to_s + "<br /><br />"
        end

        if !contact[:address].nil? and !contact[:address].eql?("")
          @table = @table + "<b>Address :</b><br /><br />" + contact[:address].to_s + ", " + contact[:city].to_s + ", " + contact[:state_or_province].to_s + ", " + contact[:post_code].to_s + ", " + contact[:country].to_s +  "<br /><br />"
        end

      end



    end
    # build a table of layers
    @table = @table + "<table style=\"width:100%\"><tr>
              <th style=\"padding: 5px;text-align: left;\"><b>Layer name</b></th>
              <th style=\"padding: 5px;text-align: left;\"><b>Layer title</b></th>
              </tr>"
    WmsLayer.where(wms_service_id: params[:id]).find_each do |layer|
      # call table creator mehtod for each layer
      tableCreator(layer)
    end
    @table = @table + "</table>"

    respond_to do |format|
      format.html { render 'services/show'}
    end
  end

  def tableCreator(layer)
      if @colorBool == 0
        @table += "<tr bgcolor=\"#E2EFCD\">"
        @colorBool = 1
      else
        @table += "<tr>"
        @colorBool = 0
      end

      @table += "<td height=\"30\" style=\"padding: 5px;text-align: left;\"><a href=\"/wms_service_layer/#{layer.id}\">#{layer.name }</a></td>"
      @table += "<td height=\"30\" style=\"padding: 5px;text-align: left;\">#{layer.title}</td>"
      @table += "</tr>"

      # recursive call
      #tableCreator(layer.id)
  end


  def favourite
    if @favourite
      respond_to do |format|
        format.html { disable_action }
        format.json { error_to_back_or_home("Could not favourite service with ID #{params[:id]} since it is already favorited.", false, 407) }
      end
    else
      new_favourite = Favourite.create(:favouritable_type => "Service", :favouritable_id => @service.id, :user_id => current_user.id)

      respond_to do |format|
        format.html { disable_action }
        format.json {
          if new_favourite
            render :json => {
                      :success => {
                        :message => "The service '#{@service.display_name}' has been successfully favourited.",
                        :resource => service_url(@service)
                      }
                    }.to_json, :status => 201
          else
            error_to_back_or_home("Could not favourite service with ID #{params[:id]}.", false, 408)
          end
        }
      end
    end
  end

  def unfavourite
    if @favourite
      deleted_favourite = Favourite.destroy(@favourite.id)

      respond_to do |format|
        format.html { disable_action }
        format.json {
          if deleted_favourite
            render :json => {
                      :success => {
                        :message => "The service '#{@service.display_name}' has been successfully unfavourited.",
                        :resource => service_url(@service)
                      }
                    }.to_json, :status => 205
          else
            error_to_back_or_home("Could not unfavourite service with ID #{params[:id]}.", false, 408)
          end
        }
      end
    else
      respond_to do |format|
        format.html { disable_action }
        format.json { error_to_back_or_home("Could not unfavourite service with ID #{params[:id]}.", false, 407) }
      end
    end
  end

  # For the 'show' service page. Each tab needs to have these ready to render the rest of the page.
  def show_page_variables
    @latest_version = @service.latest_version
    @latest_version_instance = @latest_version.service_versionified
    @latest_deployment = @service.latest_deployment

    @all_service_version_instances = @service.service_version_instances
    @all_service_types = @service.service_types

    @soaplab_server = @service.soaplab_server

    @pending_responsibility_requests = @service.pending_responsibility_requests

    if @latest_version_instance.is_a?(RestService)
      @grouped_rest_methods = @latest_version_instance.group_all_rest_methods_from_rest_resources
    end

    unless is_api_request?
      @service_tests = @service.service_tests
      @test_script_service_tests  = @service.service_tests_by_type("TestScript")
      @url_monitor_service_tests  = @service.service_tests_by_type("UrlMonitor")
    end

    @data_annotations = @service.data_example_annotations

    @has_data_examples = false
    @data_annotations.each do |d|
      unless d[:annotations].blank?
        @has_data_examples = true
        break
      end
    end

    @test_script_service_tests = @service.service_tests_by_type("TestScript")
  end

  def examples
    @latest_version = @service.latest_version
    @latest_version_instance = @latest_version.service_versionified

    @data_annotations = @service.data_example_annotations

    @has_data_examples = false
    @data_annotations.each do |d|
      unless d[:annotations].blank?
        @has_data_examples = true
        break
      end
    end

    @test_script_service_tests = @service.service_tests_by_type("TestScript")

    respond_to do |format|
      format.html { render 'services/examples'} # examples.html.erb
      format.js { render :layout => false }
    end
  end

  include CurationHelper
  def bmb
    # Get all SOAP, REST and WMS services that have not been archived
    @services = (RestService.includes(:service).where("services.archived_at is NULL") + SoapService.includes(:service).where("services.archived_at is NULL") + WmsService.includes(:service).where("services.archived_at is NULL")).sort_by { |s| s.created_at }
    @services = elixir_service_check
    respond_to do |format|
      format.xml
    end
  end

  protected

  def parse_sort_params
    sort_by_allowed = [ "created", "name", "annotated" ]
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

  def find_services

    # Sorting

    order = 'services.created_at DESC'
    order_field = nil
    order_direction = nil

    case @sort_by
      when 'created'
        order_field = "created_at"
      when 'name'
        order_field = "name"
      when 'annotated' # only curators can sort by annotation level
        if logged_in? && current_user.is_curator?
          order_field = "annotation_level"
        else
          order_field = "created_at"
        end
    end

    case @sort_order
      when 'asc'
        order_direction = 'ASC'
      when 'desc'
        order_direction = "DESC"
    end

    unless order_field.blank? or order_direction.nil?
      order = "services.#{order_field} #{order_direction}"
    end

    # Filtering

    conditions, joins = BioCatalogue::Filtering::Services.generate_conditions_and_joins_from_filters(@current_filters, params[:q])

    @filter_message = "The services index has been filtered" unless @current_filters.blank?


    if self.request.format == :bljson
      finder_options = {
        :select => "services.id, services.name, services.archived_at",
        :order => order,
        :conditions => conditions,
        :joins => joins
      }

      @services = ActiveRecord::Base.connection.select_all(Service.send(:construct_finder_arel, finder_options))
    else
      # Must check if we need to include archived services or not
      if include_archived?
        @services = Service.paginate(:page => @page,
                                     :per_page => @per_page,
                                     :order => order,
                                     :conditions => conditions,
                                     :joins => joins)
      else
        @services = Service.not_archived.paginate(:page => @page,
                                                  :per_page => @per_page,
                                                  :order => order,
                                                  :conditions => conditions,
                                                  :joins => joins)
      end

    end

  end

  def find_service
    begin
      @service = Service.find(params[:id])
    rescue
      if is_api_request?
        error_to_back_or_home("Service with ID #{params[:id]} not found.", false, 404)
      else
        raise
      end
    end
  end

  def find_favourite
    @favourite = Favourite.first(:conditions => { :favouritable_type => "Service", :favouritable_id => params[:id], :user_id => current_user.id })
  end

  def check_if_user_wants_to_categorise
    if !logged_in? and params.has_key?(:categorise)
      flash.now[:notice] = "Please login or register to categorise this service"
    end
  end

  def setup_for_index_feed
    if self.request.format == :atom
      # Remove page param
      params.delete(:page)

      # Set feed title
      @feed_title = "#{SITE_NAME} - "
      @feed_title << if (text = BioCatalogue::Filtering.filters_text_if_filters_present(@current_filters)).blank?
        "Latest Services"
      else
        "Services - #{text}"
      end
    end
  end

  def setup_for_activity_feed
    if !is_api_request? or self.request.format == :atom
      @feed_title = "#{SITE_NAME} - Service '#{BioCatalogue::Util.display_name(@service, false)}' - Latest Activity"
      @activity_logs = BioCatalogue::ActivityFeeds.activity_logs_for(:service, :style => :detailed, :scoped_object => @service, :since => Time.now.ago(120.days))
    end
  end

  def set_page_title_suffix
    @page_title_suffix = (BioCatalogue::Filtering.filters_text_if_filters_present(@current_filters) || "Browse All Services")
  end

  def set_listing_type_local
    default_type = :grid
    session_key = "services_#{action_name}_listing_type"
    set_listing_type(default_type, session_key)
  end

  def authorise
    unless BioCatalogue::Auth.allow_user_to_curate_thing?(current_user, @service)
      error_to_back_or_home("You are not allowed to perform this action")
      return false
    end

    return true
  end

  def test
     @asda="safdasdfd"
  end

end
