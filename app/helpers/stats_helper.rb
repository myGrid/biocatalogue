# BioCatalogue: app/helpers/stats_helper.rb
#
# Copyright (c) 2009, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details.

module StatsHelper
  
  def metadata_source_type_title_text(type)
    case type
      when :all
        return "ALL metadata sources"
      else
        return "#{type.to_s.titleize}"
    end
  end
  
  def render_show_hide_more_stats_links(name, hidden_class_name, top=10)
    html = ""
    
    more_text = "show all"
    less_text = "show top #{top.to_s} only"
    
    more_link_id = "#{name}_more_link"
    less_link_id = "#{name}_less_link"
    
    html << link_to_function(more_text + expand_image("0.5em"), :id => more_link_id, :class => "expand_link") do |page| 
      page.select(".#{hidden_class_name}").each do |el|
        el.show
      end
      page.toggle more_link_id, less_link_id
    end
    
    html << link_to_function(less_text + collapse_image("0.5em"), :id => less_link_id, :class => "expand_link", :style => "display:none;") do |page| 
      page.select(".#{hidden_class_name}").each do |el|
        el.hide
      end
      page.toggle more_link_id, less_link_id
    end
    
    return html
  end
  
end