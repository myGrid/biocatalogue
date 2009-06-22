# BioCatalogue: app/controllers/ratings_controller.rb
#
# Copyright (c) 2009, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

class RatingsController < ApplicationController
  before_filter :login_required
  
  # POST /ratings
  def create
    annotatable = Annotation.find_annotatable(params[:annotatable_type], params[:annotatable_id])
    
    category = params[:category]
    rating = params[:rating].to_i
    
    # TODO: move the value restriction (ie: the 1-5) to use the Annotations plugin's new config setting.
    # TODO: change this behaviour to take into account updates of ratings, since the behaviour of Annotations::Config.limits_per_source has changed!
    
    if !annotatable.nil? and !category.blank?
      anns = Annotation.find(:all, 
                             :conditions => { :annotatable_type => annotatable.class.name,
                                              :annotatable_id => annotatable.id,
                                              :attribute_id => AnnotationAttribute.find_by_name(category).id, 
                                              :source_type => current_user.class.name,
                                              :source_id => current_user.id })
      
      if anns.blank?
        # Create a new one
        ann = Annotation.new(:annotatable_type => annotatable.class.name,
                             :annotatable_id => annotatable.id,
                             :attribute_id => AnnotationAttribute.find_by_name(category).id,
                             :value => rating,
                             :source_type => current_user.class.name, 
                             :source_id => current_user.id)
      else
        # Update existing one
        ann = anns[0]
        ann.value = rating
      end
      
      unless ann.save
        # TODO: handle error
      end
    end
    
    respond_to do |format|
      format.html { render :partial => "annotations/ratings_box", 
                         :locals => { :annotatable => annotatable,
                                      :categories_config => BioCatalogue::Annotations.get_ratings_categories_config_for_model(annotatable.class.name)} }
    end
  end
  
  # DELETE /ratings
  def destroy
    annotatable = Annotation.find_annotatable(params[:annotatable_type], params[:annotatable_id])
    
    category = params[:category]
    
    if !annotatable.nil? and !category.blank?
      existing = Annotation.find(:all, 
                                 :conditions => { :annotatable_type => annotatable.class.name,
                                                  :annotatable_id => annotatable.id,
                                                  :attribute_id => AnnotationAttribute.find_by_name(category).id, 
                                                  :source_type => current_user.class.name,
                                                  :source_id => current_user.id })
      
      unless existing.blank?
        existing.each do |a|
          a.destroy
        end
      end
    end
    
    respond_to do |format|
      format.html { render :partial => "annotations/ratings_box", 
                           :locals => { :annotatable => annotatable,
                                        :categories_config => BioCatalogue::Annotations.get_ratings_categories_config_for_model(annotatable.class.name)} }
    end
  end
end
