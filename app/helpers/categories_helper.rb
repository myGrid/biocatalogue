# BioCatalogue: app/helpers/categories_helper.rb
#
# Copyright (c) 2009, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details.

module CategoriesHelper
  
  def category_hierachy_text(category)
    output = output_category_text(category, true)
    
    category_to_process = category
    
    while category_to_process.has_parent?
      category_to_process = category_to_process.parent
      output = output_category_text(category_to_process) + output
    end
    
    return output
  end
  
  def category_with_parent_text(category)
    output = output_category_text(category, true)
    
    if category.has_parent?
      output = output_category_text(category.parent) + output
    end
    
    return output
  end
  
  def render_select_tag_for_category_options_on_service_submission(element_id, disabled, style='')
    return select_tag("", options_for_select(get_categories_select_options), :id => element_id, :disabled => disabled, :style => style)
  end
  
  protected
  
  def output_category_text(category, current=false)
    if current
      return "<b>#{h(category.name)}</b>"
    else
      "#{h(category.name)}  &gt;  "
    end
  end
  
  def get_categories_select_options
    options = [ ]
    
    category_tree = Category.tree
    
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