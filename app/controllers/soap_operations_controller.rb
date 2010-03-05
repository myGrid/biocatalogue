# BioCatalogue: app/controllers/soap_operations_controller.rb
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details.


class SoapOperationsController < ApplicationController
  
  before_filter :disable_action, :only => [ :new, :create, :edit, :update, :destroy ]
  before_filter :disable_action_for_api, :except => [ :index, :show, :annotations, :filters ]
  
  before_filter :parse_current_filters, :only => [ :index ]
  
  before_filter :get_filter_groups, :only => [ :filters ]
  
  before_filter :parse_sort_params, :only => [ :index ]
  
  before_filter :find_soap_operations, :only => [ :index ]
  
  before_filter :find_soap_operation, :only => [ :show, :annotations ]
  
  def index
    respond_to do |format|
      format.html { disable_action }
      format.xml # index.xml.builder
      format.json { } #render :json =>  @soap_operations.to_json }
    end
  end
  
  def show
    respond_to do |format|
      format.html { redirect_to url_for_web_interface(@soap_operation) }
      format.xml  # show.xml.builder
    end
  end
  
  def annotations
    respond_to do |format|
      format.html { disable_action }
      format.xml { redirect_to(generate_include_filter_url(:asop, @soap_operation.id, "annotations", :xml)) }
      format.json { render :json => @soap_operation.annotations.paginate(:page => @page, :per_page => @per_page).to_json }
    end
  end
  
  def filters
    respond_to do |format|
      format.html { disable_action }
      format.xml # filters.xml.builder
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
    @soap_operation = SoapOperation.find(params[:id])
  end
  
end
