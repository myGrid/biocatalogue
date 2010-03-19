# BioCatalogue: app/helpers/rest_methods_helper.rb
#
# Copyright (c) 2008, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details.

module RestMethodsHelper
  include ApplicationHelper
    
  # This method will create a link to a popup dialog, which allows the user to
  # add more representations to the given RestMethod.
  #
  # CONFIGURATION OPTIONS (all these options are optional)
  #  :tooltip_text - text that will be displayed in a tooltip over the text.
  #    default: 'Add new representations to this endpoint'
  #  :link_text - text to be displayed as part of the link.
  #    default: 'Add new Representations'
  #  :style - any CSS inline styles that need to be applied to the text.
  #    default: 'float:right; margin: 0px 10px 1px 10px;'
  #  :class - any CSS class that need to be applied to the text.
  #    default: nil
  def add_representations_by_popup(method, http_cycle, *args)
    return '' unless method.class.name == "RestMethod"

    http_cycle.downcase!
    return unless %w{ request response }.include?(http_cycle)
    
    options = args.extract_options!
    
    # default config options
    options.reverse_merge!(:style => "",
                           :class => nil,
                           :link_text => "Add " + (http_cycle=='request' ? 'In':'Out') + "put Representations",
                           :tooltip_text => "Add new representations to this endpoint")

    default_styles = ""
    default_styles += "float: right; " unless options[:style].include?('float')
    default_styles += "font-weight: bold; " unless options[:style].include?('font-weight')
    
    options[:style] = default_styles + options[:style]

    link_content = ''
    
    if logged_in?
      inner_html = image_tag("add.png")
      inner_html += content_tag(:span, " " + options[:link_text], :style => options[:style])
      
      css_hash = {:style => options[:style],
                  :class => options[:class],
                  :alt => options[:tooltip_text],
                  :title => tooltip_title_attrib(options[:tooltip_text]) }

      url_hash = {:controller => "rest_representations",
                  :action => "new_popup", 
                  :rest_method_id => method.id,
                  :http_cycle => http_cycle}

      fail_value = "alert('Sorry, an error has occurred.'); RedBox.close();"
      id_value = "new_representation_for_#{method.class.name}_#{method.id}_redbox"

      combined_hash = {:url => url_hash, :id => id_value, :failure => fail_value}
      link_content = link_to_remote_redbox(inner_html, combined_hash, css_hash)
    else # NOT LOGGED IN
      inner_html = image_tag("add_inactive.png")
      inner_html += content_tag(:span, options[:link_text], :style => options[:style])
      
      link_content = link_to(inner_html, login_path, 
                             :class => options[:class], 
                             :style => options[:style], 
                             :title => tooltip_title_attrib("Login to #{options[:tooltip_text].downcase}"))
    end
    
    return link_content
  end
  
  
  
  # This method will create an dropdown title (in the form of a link) for 
  # RestParameters, and RestRepresentations which allows the components to be 
  # expanded or collapsed.
  #
  # CONFIGURATION OPTIONS (all these options are optional)
  #  :link_text - text to be displayed as part of the link.
  #    default: update_element_id (the ID of the element to be expanded or collapsed)
  #  :class - any CSS class that need to be applied to the text.
  #    default: nil
  #  :icon_left_margin - the left margin of the expand / collapse icon
  #    default: "5px"
  #  :icon_float - the CSS float value for the icon i.e. 'left', right', etc.  This OVERRIDES :icon_left_margin
  #    default: ''
def create_expand_collapse_link(update_element_id, *args)
    return '' if update_element_id.blank?
    
    options = args.extract_options!
    # default config options
    options.reverse_merge!(:link_text => update_element_id,
                           :class => nil,
                           :icon_left_margin => "5px",
                           :icon_float => "")

    expand_link = options[:link_text] + expand_image(options[:icon_left_margin], options[:icon_float])
    collapse_link = options[:link_text] + collapse_image(options[:icon_left_margin], options[:icon_float])

    expand_link_id = update_element_id + '_name_more_link'
    collapse_link_id = update_element_id + '_name_less_link'
    
    expand_link_content = link_to_function(expand_link, :id => expand_link_id) do |page| 
                            page.toggle expand_link_id, collapse_link_id
                            page.visual_effect :toggle_blind, update_element_id, :duration => '0.2'
                          end

    collapse_link_content = link_to_function(collapse_link, :id => collapse_link_id, :style => "display:none;") do |page| 
                              page.toggle expand_link_id, collapse_link_id
                              page.visual_effect :toggle_blind, update_element_id, :duration => '0.2'
                            end 
                            
    span_content = expand_link_content + collapse_link_content

    return content_tag(:span, span_content, :class => options[:class])
  end
end
