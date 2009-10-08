# BioCatalogue: app/controllers/tags_controller.rb
#
# Copyright (c) 2008-2009, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details.

class TagsController < ApplicationController
  skip_before_filter :verify_authenticity_token, :only => [ :auto_complete ]
  
  before_filter :find_tags, :only => [ :index ]
  before_filter :parse_tag_name, :only => [ :show, :destroy ]
  before_filter :find_tag_results, :only => [ :show ]
  
  def index
    respond_to do |format|
      format.html # index.html.erb
      format.xml  # index.xml.builder
    end
  end
  
  def show
    respond_to do |format|
      format.html # show.html.erb
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
                                                    :source_type => current_user.class.name,
                                                    :source_id => current_user.id,
                                                    :value => @tag_name })
        
        unless existing.blank?
          existing.each do |a|
            a.destroy
          end
        end
      end
    end
    
    respond_to do |format|
      format.html { render :partial => 'annotations/tags_box_inner_tag_cloud', 
                           :locals => { :tag_annotations => BioCatalogue::Annotations.get_tag_annotations_for_annotatable(annotatable),
                                        :annotatable => annotatable } }
    end
  end
  
protected

  def find_tags
    @tags = BioCatalogue::Tags.get_tags(params[:limit])
    
    # Sort tags differently if a certain action
    if action_name == "index" and params[:format] == "xml"
      @tags.sort! { |a,b| b['count'].to_i <=> a['count'].to_i }
    end
  end
  
  def parse_tag_name
    if action_name == 'destroy'
      @tag_name = params[:tag_name]
    else
      dup_params = BioCatalogue::Util.duplicate_params(params)
      dup_params[:tag_keyword] = dup_params[:id]
      @tag_name = BioCatalogue::Tags.get_tag_name_from_params(dup_params)
    end
  end
  
  def find_tag_results
    @service_ids = [ ]
    
    unless @tag_name.nil?
      @service_ids = BioCatalogue::Tags.get_service_ids_for_tag(@tag_name)
    end
  end
  
end
