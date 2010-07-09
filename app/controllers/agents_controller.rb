# BioCatalogue: app/controllers/agents_controller.rb
#
# Copyright (c) 2009-2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details.

class AgentsController < ApplicationController
  
  before_filter :disable_action, :only => [ :new, :edit, :create, :update, :destroy ]
  before_filter :disable_action_for_api, :except => [ :index, :show, :annotations_by, :services ]
  
  before_filter :parse_sort_params, :only => [ :index ]
  
  before_filter :find_agents, :only => [ :index ]
  
  before_filter :find_agent, :only => [ :show, :annotations_by ]
  
  # GET /agents
  # GET /agents.xml
  def index
    respond_to do |format|
      format.html # index.html.erb
      format.xml  # index.xml.builder
    end
  end

  # GET /agents/1
  # GET /agents/1.xml
  def show
    unless is_api_request?
      @agents_services = @agent.services.paginate(:page => @page,
                                                  :order => "created_at DESC")
                                                
      agents_annotated_service_ids = @agent.annotated_service_ids 
      @agents_paged_annotated_services_ids = agents_annotated_service_ids.paginate(:page => @page, :per_page => @per_page)
      @agents_paged_annotated_services = BioCatalogue::Mapper.item_ids_to_model_objects(@agents_paged_annotated_services_ids, "Service")
    end
                                                        
    respond_to do |format|
      format.html # show.html.erb
      format.xml  # show.xml.builder
      format.json { render :json => @agent.to_json }
    end
  end
  
  def annotations_by
    respond_to do |format|
      format.html { disable_action }
      format.xml { redirect_to(generate_include_filter_url(:soa, @agent.id, "annotations", :xml)) }
      format.json { render :json => @agent.annotations_by.paginate(:page => @page, :per_page => @per_page).to_json }
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
  
  def find_agents
    
    # Sorting
    
    order = 'agents.created_at DESC'
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
      order = "agents.#{order_field} #{order_direction}"
    end
    
    @agents = Agent.paginate(:page => @page,
                             :per_page => @per_page,
                             :order => order)
  
  end
  
  def find_agent
    @agent = Agent.find(params[:id])
  end

end
