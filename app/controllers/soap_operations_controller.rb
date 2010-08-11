# BioCatalogue: app/controllers/soap_operations_controller.rb
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details.


class SoapOperationsController < ApplicationController
  
  before_filter :disable_action, :only => [ :new, :create, :edit, :update, :destroy ]
  before_filter :disable_action_for_api, :except => [ :index, :show, :annotations, :filters, :inputs, :outputs ]
  
  before_filter :parse_current_filters, :only => [ :index ]
  
  before_filter :get_filter_groups, :only => [ :filters ]
  
  before_filter :parse_sort_params, :only => [ :index ]
  
  before_filter :find_soap_operations, :only => [ :index ]
  
  before_filter :find_soap_operation, :only => [ :show, :annotations, :inputs, :outputs ]
  
  def index
    respond_to do |format|
      format.html { disable_action }
      format.xml # index.xml.builder
      format.json { render :json => BioCatalogue::Api::Json.collection(@soap_operations, true).to_json }
    end
  end
  
  def show
    @soap_service = @soap_operation.soap_service
    
    respond_to do |format|
      format.html # show.html.erb
      format.xml  # show.xml.builder
      format.json { render :json => @soap_operation.to_json }
    end
  end

  def inputs 
    respond_to do |format|
      format.html { disable_action }
      format.xml  # inputs.xml.builder
      format.json { render :json => @soap_operation.to_custom_json("inputs") }
    end
  end

  def outputs 
    respond_to do |format|
      format.html { disable_action }
      format.xml  # outputs.xml.builder
      format.json { render :json => @soap_operation.to_custom_json("outputs") }
    end
  end
  
  def annotations
    respond_to do |format|
      format.html { disable_action }
      format.xml {
        
        # Add SoapOperation filter
        new_params = BioCatalogue::Filtering.add_filter_to_params(params, :asop, @soap_operation.id)
        
        # Now add any other filters, if specified by "also=..."
        
        if @api_params[:also].include?('inputs')
          @soap_operation.soap_inputs.find(:all, :select => "id").each do |input|
            new_params = BioCatalogue::Filtering.add_filter_to_params(new_params, :asin, input.id)
          end
        end
        
        if @api_params[:also].include?('outputs')
          @soap_operation.soap_outputs.find(:all, :select => "id").each do |output|
            new_params = BioCatalogue::Filtering.add_filter_to_params(new_params, :asout, output.id)
          end
        end
        
        redirect_to(generate_filter_url(new_params, "annotations", :xml))
        
      }
      format.json {
        # TODO: implement ?include=inputs,outputs
        render :json => BioCatalogue::Api::Json.collection(@soap_operation.annotations.paginate(:page => @page, :per_page => @per_page), false).to_json 
      }
    end
  end
  
  def filters
    respond_to do |format|
      format.html { disable_action }
      format.xml # filters.xml.builder
      format.json { render :json => BioCatalogue::Api::Json.filter_groups(@filter_groups).to_json }
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
  
  def find_soap_operations
    
    # Sorting
    
    order = 'soap_operations.created_at DESC'
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
      order = "soap_operations.#{order_field} #{order_direction}"
    end
    
    # Filtering
    
    conditions, joins = BioCatalogue::Filtering::SoapOperations.generate_conditions_and_joins_from_filters(@current_filters, params[:q])
    
    @soap_operations = SoapOperation.paginate(:page => @page,
                                              :per_page => @per_page,
                                              :order => order,
                                              :conditions => conditions,
                                              :joins => joins)
  end
  
  def find_soap_operation
    @soap_operation = SoapOperation.find(params[:id], :include => [ :soap_inputs, :soap_outputs ])
  end
  
end
