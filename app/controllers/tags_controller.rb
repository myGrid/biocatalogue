# BioCatalogue: app/controllers/tags_controller.rb
#
# Copyright (c) 2008-2011, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details.

class TagsController < ApplicationController
  
  before_filter :disable_action_for_api, :except => [ :index, :show ]
  
  skip_before_filter :verify_authenticity_token, :only => [ :auto_complete ]
  
  before_filter :find_tags, :only => [ :index ]
  before_filter :find_tag, :only => [ :show, :destroy, :destroy_taggings ]
  before_filter :find_tag_results, :only => [ :show ]
  before_filter :get_tag_items_count, :only => [ :show ]
  
  def index
    respond_to do |format|
      format.html # index.html.erb
      format.xml  # index.xml.builder
      format.json { render :json => BioCatalogue::Api::Json.index("tags", json_api_params, @tags, :total_tags_count => @total_tags_count, :total_pages => @total_pages).to_json }
    end
  end
  
  def show
    respond_to do |format|
      format.html # show.html.erb
      format.xml  # show.xml.builder
      format.json { render :json => BioCatalogue::Api::Json.tag(@tag.name, @tag.label, @total_items_count).to_json }
    end
  end
  
  def auto_complete
    @tag_fragment = '';
    
    if params[:annotations] and params[:annotations][:tags]
      @tag_fragment = params[:annotations][:tags]
    elsif  params[:annotation] and params[:annotation][:value]
      @tag_fragment = params[:annotation][:value]
    end
    
    @tags = BioCatalogue::Tags.get_tag_suggestions(@tag_fragment, 50)
                     
    render :inline => "<%= auto_complete_result @tags, 'name' %>", :layout => false
  end
  
  def destroy
    raise NotImplemented
  end
  
  def destroy_taggings
    annotatable = Annotation.find_annotatable(params[:annotatable_type], params[:annotatable_id])
    
    if !annotatable.nil?
      existing = Annotation.find(:all, 
                                 :conditions => { :annotatable_type => annotatable.class.name,
                                                  :annotatable_id => annotatable.id,
                                                  :attribute_id => AnnotationAttribute.find_by_name("tag").id, 
                                                  :value_type => "Tag",
                                                  :value_id => @tag.id })
      
      unless existing.blank?
        existing.each do |a|
          submitters = [ BioCatalogue::Mapper.compound_id_for_model_object(a.source) ]
          if BioCatalogue::Auth.allow_user_to_curate_thing?(current_user, :tag, :tag_submitters => submitters)            
            a.destroy
          end
        end
      end
    end
    
    respond_to do |format|
      format.html { render :partial => 'annotations/tags_box_inner_tag_cloud', 
                           :locals => { :tags => BioCatalogue::Annotations.get_tag_annotations_for_annotatable(annotatable),
                                        :annotatable => annotatable } }
    end
  end
  
protected

  def find_tags
    @sort = params[:sort].try(:to_sym)
    
    if is_api_request?
      @sort = :counts if @sort.blank? or ![ :counts, :name ].include?(@sort)
      @tags = BioCatalogue::Tags.get_tags(:sort => @sort, :page => @page, :per_page => @per_page)
    else
      @sort = :name if @sort.blank? or ![ :counts, :name ].include?(@sort)
      # TODO: check this is the right behaviour and not too bad in terms of performance
      @tags = BioCatalogue::Tags.get_tags(:sort => @sort)
    end
    
    @total_tags_count = BioCatalogue::Tags.get_total_tags_count
    
    # NOTE: there is an assumption here this index has not been 
    # filtered/restricted in any way apart from paging. 
    @total_pages = (@total_tags_count.to_f / @per_page.to_f).ceil
  end
  
  def find_tag
    if action_name == 'destroy_taggings'
      tag_name = params[:tag_name]
    else
      dup_params = BioCatalogue::Util.duplicate_params(params)
      dup_params[:tag_keyword] = dup_params[:id]
      tag_name = BioCatalogue::Tags.get_tag_name_from_params(dup_params)
    end

    @tag = Tag.find_by_name(tag_name)

    raise ActiveRecord::RecordNotFound.new if @tag.nil?
  end
  
  def find_tag_results
    unless is_api_request?
      @service_ids = [ ]
      
      unless @tag.blank?
        @service_ids = BioCatalogue::Tags.get_service_ids_for_tag(@tag.name)
      end
    end
  end
  
  def get_tag_items_count
    unless @tag.blank?
      @total_items_count = BioCatalogue::Tags.get_total_items_count_for_tag_name(@tag.name)
    end
  end
  
end
