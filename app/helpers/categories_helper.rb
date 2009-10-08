# BioCatalogue: app/helpers/categories_helper.rb
#
# Copyright (c) 2009, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details.

module CategoriesHelper
  
  def category_hierachy_text(category)
    BioCatalogue::Categorising.category_hierachy_text(category)
  end
  
  def category_with_parent_text(category)
    BioCatalogue::Categorising.category_with_parent_text(category)
  end
  
  def render_select_tag_for_category_options_on_service_submission(element_id, disabled, style='')
    return select_tag("", options_for_select(get_categories_select_options), :id => element_id, :disabled => disabled, :style => style)
  end
  
  protected
  
  def get_categories_select_options
    options = [ ]
    
    category_tree = Category.root_categories
    
    category_tree.each do |category|
      options = options + process_category_for_select_options(category)
    end
    
    return options
  end
  
  def process_category_for_select_options(parent_category, depth=0)
    options = [ ]
    
    options << select_option_for_category(parent_category, depth)
    parent_category.children.each do |category|
      options = options + process_category_for_select_options(category,depth+1)
    end
    
    return options
  end
  
  def select_option_for_category(category, depth=0)
    return [ "#{'---'*depth} #{h(category.name)}", category.id ]
  end
  
end