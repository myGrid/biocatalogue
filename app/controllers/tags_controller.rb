# BioCatalogue: app/controllers/tags_controller.rb
#
# Copyright (c) 2008-2009, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details.

class TagsController < ApplicationController
  
  before_filter :disable_action_for_api, :except => [ :index, :show ]
  
  skip_before_filter :verify_authenticity_token, :only => [ :auto_complete ]
  
  before_filter :find_tags, :only => [ :index ]
  before_filter :parse_tag_name, :only => [ :show, :destroy ]
  before_filter :find_tag_results, :only => [ :show ]
  before_filter :get_tag_items_count, :only => [ :show ]
  
  def index
    respond_to do |format|
      format.html # index.html.erb
      format.xml  # index.xml.builder
    end
  end
  
  def show
    respond_to do |format|
      format.html # show.html.erb
      format.xml  # show.xml.builder
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
  
  # DELETE /tags
  def destroy
    unless @tag_name.blank?
      annotatable = Annotation.find_annotatable(params[:annotatable_type], params[:annotatable_id])
      
      if !annotatable.nil?
        existing = Annotation.find(:all, 
                                   :conditions => { :annotatable_type => annotatable.class.name,
                                                    :annotatable_id => annotatable.id,
                                                    :attribute_id => AnnotationAttribute.find_by_name("tag").id, 
                                                    :value => @tag_name })
        
        unless existing.blank?
          existing.each do |a|
            submitters = [ BioCatalogue::Mapper.compound_id_for_model_object(a.source) ]
            if BioCatalogue::Auth.allow_user_to_curate_thing?(current_user, :tag, :tag_submitters => submitters)            
              a.destroy
            end
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
    @sort = :counts if @sort.blank? or ![ :counts, :name ].include?(@sort) 
    
    if is_api_request?
      # Use cache only if it's the first page...
      if @page == 1
        cache_key = BioCatalogue::CacheHelper.cache_key_for(:tags_index, "api", @page, @per_page, @sort, @limit)
        
        # Try and get it from the cache...
        @tags = Rails.cache.read(cache_key)
        
        if @tags.nil?
          @tags = BioCatalogue::Tags.get_tags(:limit => @limit, :sort => @sort, :page => @page, :per_page => @per_page)
          
          # Finally write it to the cache...
          Rails.cache.write(cache_key, @tags, :expires_in => TAGS_INDEX_CACHE_TIME)
        end
      else
        @tags = BioCatalogue::Tags.get_tags(:limit => @limit, :sort => @sort, :page => @page, :per_page => @per_page)
      end
    else
      @tags = BioCatalogue::Tags.get_tags(:limit => @limit, :sort => @sort)
    end
  
    @total_tags_count = BioCatalogue::Tags.get_total_tags_count
  end
  
  def parse_tag_name
    if action_name == 'destroy'
      @tag_name = params[:tag_name]
    else
      dup_params = BioCatalogue::Util.duplicate_params(params)
      dup_params[:tag_keyword] = dup_params[:id]
      @tag_name = BioCatalogue::Tags.get_tag_name_from_params(dup_params)
      @tag_namespace, @tag_display_name = BioCatalogue::Tags.split_ontology_term_uri(@tag_name)
    end
  end
  
  def find_tag_results
    unless is_api_request?
      @service_ids = [ ]
      
      unless @tag_name.blank?
        @service_ids = BioCatalogue::Tags.get_service_ids_for_tag(@tag_name)
      end
    end
  end
  
  def get_tag_items_count
    unless @tag_name.blank?
      @total_items_count = BioCatalogue::Tags.get_total_items_count_for_tag_name(@tag_name)
    end
  end
  
end
