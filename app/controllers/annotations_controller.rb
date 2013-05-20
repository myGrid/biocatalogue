# BioCatalogue: app/controllers/annotations_controller.rb
#
# Copyright (c) 2009, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details.

#=====
# This extends the Annotations controller defined in the Annotations plugin.
#=====

#require_dependency RAILS_ROOT + '/vendor/plugins/annotations/lib/app/controllers/annotations_controller'
require_dependency File.join(Gem.loaded_specs['my_annotations'].full_gem_path,'lib','app','controllers','annotations_controller')

class AnnotationsController < ApplicationController
  
  # Disable some of the actions provided in the controller in the plugin.
  before_filter :disable_action, :only => [ :new, :edit ]
  before_filter :disable_action_for_api, :except => [ :index, :show, :filters, :bulk_create, :filtered_index ]
  
  before_filter :add_use_tab_cookie_to_session, :only => [ :create, :create_multiple, :update, :destroy, :set_as_field ]
  
  before_filter :login_or_oauth_required, :only => [ :new, :create, :edit, :update, :destroy, :edit_popup, :create_inline, :promote_alternative_name, :bulk_create ]

  before_filter :parse_filtered_index_params, :only => :filtered_index
  
  before_filter :parse_current_filters, :only => [ :index, :filtered_index ]
  
  before_filter :get_filter_groups, :only => [ :filters ]
  
  before_filter :parse_sort_params, :only => [ :index, :filtered_index ]
  
  before_filter :find_annotations, :only => [ :index, :filtered_index ]
  
  before_filter :find_annotation, :only => [ :show, :edit, :update, :destroy, :edit_popup, :download, :promote_alternative_name ]
  
  before_filter :find_annotatable, :only => [ :new, :create, :new_popup, :create_inline ]
  
  skip_before_filter :authorise_action
  before_filter :authorise, :only =>  [ :edit, :edit_popup, :update, :destroy, :promote_alternative_name, :bulk_create ]
  
  def index
    respond_to do |format|
      format.html { disable_action }
      format.xml # index.xml.builder
      format.json { render :json => BioCatalogue::Api::Json.index("annotations", json_api_params, @annotations).to_json }
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
  
  def show
    respond_to do |format|
      format.html # show.html.erb
      format.xml  # show.xml.builder
      format.json { render :json => @annotation.to_json }
    end
  end
  
  def new_popup
    if @annotatable.nil?
      flash[:error] = "Could not begin annotation (the thing you want to annotate is not specified or is invalid). Please contact the #{SITE_NAME} folks."
      respond_to do |format|
        format.js {
          render :update do |page|
            page.redirect_to root_url
          end
        }
      end
    else
      @annotation = Annotation.new
    
      # Populate from query string values provided in the URL (if provided)
      @annotation.annotatable_type = params[:annotatable_type]
      @annotation.annotatable_id = params[:annotatable_id]
      @annotation.attribute_name = params[:attribute_name]
      
      @multiple = !params[:multiple].nil? && (params[:multiple].downcase == "true")
      @separator = params[:separator].nil? ? '' : params[:separator]
  
      respond_to do |format|
        format.js { render :layout => false }
      end
    end
  end
  
  def edit_popup
    respond_to do |format|
      format.js { render :layout => false }
    end
  end
  
  # PUT /annotations/1
  # PUT /annotations/1.xml
  def update
    # Only allow update for certain kind of annotation values
    if [ 'TextValue', 'NumberValue' ].include?(@annotation.value_type)
      @annotation.value.ann_content = params[:annotation][:value]
      @annotation.version_creator_id = current_user.id
      respond_to do |format|
        if @annotation.save
          flash[:notice] = 'Annotation was successfully updated.'

          url_to_redirect_to = if @annotation.annotatable_type =~ /RestParameter|RestRepresentation/
                                 request.env["HTTP_REFERER"]
                               else
                                 url_for_web_interface(@annotation.annotatable) || home_url
                               end

          format.html { redirect_to url_to_redirect_to }
          format.xml  { head :ok }
        else
          format.html { render :action => "edit" }
          format.xml  { render :xml => @annotation.errors, :status => :unprocessable_entity }
        end
      end
    else
      error_to_back_or_home "Cannot perform this action!"
    end
  end
  
  def create_inline
    # Set source as the current logged in user
    params[:annotation][:source_type] = current_user.class.name
    params[:annotation][:source_id] = current_user.id
    
    # Do we create multiple annotations or a single annotation?
    if params[:multiple]
      success, annotations, errors = Annotation.create_multiple(params[:annotation], params[:separator])
    else
      annotation = Annotation.new(params[:annotation])
      annotation.annotatable = @annotatable
      annotation.save!    # This will raise an exception if it fails
    end
    
    respond_to do |format|
      format.html { render :partial => "annotations/#{params[:partial]}", :locals => { :annotatable => @annotatable } }
      format.js { render :partial => "annotations/#{params[:partial]}", :locals => { :annotatable => @annotatable } } 
    end
  end
  
  def download
    send_data(@annotation.value_content, :type => "text/plain", :disposition => 'inline')
  end
  
  def promote_alternative_name
    if @annotation.attribute_name.downcase == "alternative_name" &&
      BioCatalogue::Auth.allow_user_to_curate_thing?(current_user, @annotation.annotatable)
      
      annotatable = @annotation.annotatable
      annotatable.name = @annotation.value_content
      
      if annotatable.save && @annotation.destroy
        respond_to do |format|
          flash[:notice] = "Display name successfully updated"
          format.html { redirect_to :back }
        end
      else
        error_to_back_or_home "Sorry, something went wrong. Please try again. If this problem persists we would appreciate it if you contacted us."
      end
    else
      error_to_back_or_home "You are not allowed to do that!"
    end
  end
  
  def filters
    respond_to do |format|
      format.html { disable_action }
      format.xml # filters.xml.builder
      format.json { render :json => BioCatalogue::Api::Json.filter_groups(@filter_groups).to_json }
    end
  end
  
  # POST /annotations/bulk_create
  #
  # Example Input (application/json):
  #
  # {
  #   "bulk_annotations": [ {
  #     "resource": "http://www.biocatalogue.org/soap_inputs/23",
  #     "annotations": {
  #       "tag": [ "x", "y", "z" ],
  #       "description": "ihouh uh ouho ouh"
  #     }
  #   },
  #   {
  #     "resource": "http://www.biocatalogue.org/soap_operations/237",
  #     "annotations": {
  #       "tag": [ "x", "y", "z" ],
  #       "description": "ihouh uh ouho ouh"
  #     }
  #   } ]
  # }
  #
  # Example Output (application/json):
  #
  # {
  #   "bulk_annotations": [ {
  #     "resource": "http://www.biocatalogue.org/soap_inputs/23",
  #     "annotations": [
  #       <<items in the Annotation resource JSON format>>
  #     ]
  #   },
  #   {
  #     "resource": "http://www.biocatalogue.org/soap_operations/237",
  #     "annotations": [
  #       <<items in the Annotation resource JSON format>>
  #     ] 
  #   } ]
  # }
  #
  # Note that the output will ONLY include the valid resources and successfully
  # created annotations.
  def bulk_create
    results = BioCatalogue::Annotations.bulk_create(params["bulk_annotations"], current_user)
    
    respond_to do |format|
      format.html { disable_action }
      # FIXME: format.xml  { render :xml => results.to_xml(:root => "bulkAnnotations", :camelize => true, :skip_types => true) }
      format.json { render :json => { "bulk_annotations" => results }.to_json }
    end
  end
  
  protected
  
  def parse_sort_params
    sort_by_allowed = [ "created", "modified" ]
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
  
  def find_annotations
    
    # Sorting
    
    order = 'annotations.created_at DESC'
    order_field = nil
    order_direction = nil
    
    case @sort_by
      when 'created'
        order_field = "created_at"
      when 'modified'
        order_field = "updated_at"
    end
    
    case @sort_order
      when 'asc'
        order_direction = 'ASC'
      when 'desc'
        order_direction = "DESC"
    end
    
    unless order_field.blank? or order_direction.nil?
      order = "annotations.#{order_field} #{order_direction}"
    end
    
    # Filtering
    
    conditions, joins = BioCatalogue::Filtering::Annotations.generate_conditions_and_joins_from_filters(@current_filters, params[:q])
    
    @annotations = Annotation.paginate(:page => @page,
                                       :per_page => @per_page,
                                       :order => order,
                                       :conditions => conditions,
                                       :joins => joins)
  end
  
  def authorise
    allowed = false
    case action_name.downcase
      when "edit", "update", "edit_popup"
        allowed = mine?(@annotation)
      when "bulk_create"
        allowed = (current_user.is_curator? or current_user.is_admin?)
      else
        allowed = BioCatalogue::Auth.allow_user_to_curate_thing?(current_user, @annotation)
    end
    
    unless allowed
      error_to_back_or_home('You are not allowed to perform this action', true)
    end
    
    return allowed
  end
  
end
