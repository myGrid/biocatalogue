# BioCatalogue: app/controllers/tags_controller.rb
#
# Copyright (c) 2009, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details.

class TagsController < ApplicationController
  before_filter :find_tags, :only => [ :index ]
  before_filter :find_tag_and_results, :only => [ :show ]
  
  def index
    respond_to do |format|
      format.html # index.rhtml
    end
  end
  
  def show
    respond_to do |format|
      format.html # show.rhtml
    end
  end
  
  def auto_complete
#    text = '';
#    
#    if params[:tag_list]
#      text = params[:tag_list]
#    elsif params[:tags_input]
#      text = params[:tags_input]
#    end
#    
#    @tags = Tag.find(:all, 
#                     :conditions => ["LOWER(name) LIKE ?", text.downcase + '%'], 
#                     :order => 'name ASC', 
#                     :limit => 20, 
#                     :select => 'DISTINCT *')
#    render :inline => "<%= auto_complete_result @tags, 'name' %>"
  end
  
protected

  def find_tags
    # TODO: potentially move this kind of functionality into the Annotations plugin.
    
    # NOTE: this query has only been tested to work with MySQL 5.0.x
    sql = "SELECT annotations.value, COUNT(*) AS count 
          FROM annotations 
          INNER JOIN annotation_attributes ON annotations.attribute_id = annotation_attributes.id 
          WHERE annotation_attributes.name = 'tag' 
          GROUP BY annotations.value 
          ORDER BY COUNT(*) DESC"
    
    # If limit has been provided in the URL then add that to query
    # (this allows customisation of the size of the tag cloud, whilst keeping into account ranking of tags).
    if !params[:limit].nil? && params[:limit].is_a?(Fixnum) && params[:limit].to_i < 0
      sql += " LIMIT #{params[:limit]}"
    end
    
    # This will return regular Annotation objects BUT
    # with only the "value" attribute (which is equivalent to the tag name) AND 
    # an extra "count" attribute to show how many of those tags exist in the db.
    tag_annotations = Annotation.find_by_sql(sql)
    
    # Sort by the tag names
    @tags = tag_annotations.sort! { |a,b| a.value.downcase <=> b.value.downcase }
  end
  
  def find_tag_and_results
    @tag = params[:tag]
    
    @count = 0
    @results = { }
    
    unless @tag.nil?
      tagged_items = Annotation.find_annotatables_with_attribute_name_and_value("tag", @tag)
      
      # Use the same grouping and type restrictions as for search
      search_type_models = VALID_SEARCH_TYPES.map{|t| t.classify.constantize}
    
      search_type_models.each do |m|
        m_name = m.to_s
        @results[m_name] = BioCatalogue::Util.discover_model_objects_from_collection(m, tagged_items)
        @count += @results[m_name].length
      end
    end
  end
  
end
