# BioCatalogue: app/helpers/ratings_helper.rb
#
# Copyright (c) 2009, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

module RatingsHelper
  include ApplicationHelper
  
  # Gets the average rating for a specific item (has to be an annotatable item),
  # in the category specified.
  # The 'category' is should be the annotation attribute name for that category.
  def get_average_rating(annotatable, category)
    avg = 0.0
    
    anns = annotatable.annotations_with_attribute(category)
    
    unless anns.empty?
      # Note: this assumes that the values of the annotations are within constraints (ie: [1,2,3,4,5])
      avg = number_with_precision(anns.map{|x| x.value.to_i}.mean, :precision => 1)
    end
    
    return avg.to_f
  end
  
  # Gets the overall average ratings for a specific item (has to be an annotatable item).
  # This is the average of all the average ratings of all the categories of ratings for that annotatable model type.
  def get_overall_average_rating(annotatable)
    avg = 0.0
    
    ratings = [ ]
    
    BioCatalogue::Annotations.get_ratings_categories_config_for_model(annotatable.class.name).keys.each do |category|
      cat_avg = get_average_rating(annotatable, category)
      ratings << cat_avg if cat_avg > 0
    end
    
    avg = number_with_precision(ratings.mean, :precision => 1)
    
    return avg.to_f
  end
  
  def get_users_rating(annotatable, user, category)
    rating = 0
    
    rating_annotation = annotatable.annotations_with_attribute_and_by_source(category, user).first
    unless rating_annotation.nil?
      # Note: this assumes that the values of the annotations are within constraints (ie: [1,2,3,4,5])
      rating = rating_annotation.value.to_i
    end
    
    return rating
  end
  
  def get_count_of_ratings(annotatable, category)
    # Note: this assumes that the values of the annotations are within constraints (ie: [1,2,3,4,5])
    annotatable.annotations_with_attribute(category).length
  end
  
  def get_overall_count_of_ratings(annotatable)
    total_count = 0
    
    BioCatalogue::Annotations.get_ratings_categories_config_for_model(annotatable.class.name).keys.each do |category|
      total_count += get_count_of_ratings(annotatable, category)
    end
    
    return total_count
  end
  
  def rating_to_percentage(rating)
    return ((rating/5.to_f)*100).round
  end
  
  def render_star_rating_create_link(annotatable, category, rating_level, div_id)
    return link_to_remote(rating_level.to_s,
                          :url => "#{create_rating_url}?annotatable_type=#{annotatable.class.name}&annotatable_id=#{annotatable.id}&category=#{category}&rating=#{rating_level}",
                          :method => :post,
                          :update => { :success => div_id, :failure => '' },
                          :loading => "Element.show('ratings_spinner')",
                          :complete => "Element.hide('ratings_spinner')", 
                          :success => "new Effect.Highlight('#{div_id}', { duration: 0.5 });",
                          :failure => "Element.hide('ratings_spinner'); alert('Sorry, an error has occurred.');",
                          :html => { :class  => "#{rating_level_to_word(rating_level)}-stars", :title => "#{rating_level} star out of 5" } )
  end
  
  def rating_level_to_word(rating_level)
    word = ""
    
    case rating_level
      when 1
        word = "one"
      when 2
        word = "two"
      when 3
        word = "three"
      when 4
        word = "four"
      when 5
        word = "five"
    end
    
    return word
  end
  
end