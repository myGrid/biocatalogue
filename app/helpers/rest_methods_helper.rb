# BioCatalogue: app/helpers/rest_methods_helper.rb
#
# Copyright (c) 2008, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details.

module RestMethodsHelper
  include ApplicationHelper
  
  
  # This method will create a link to a popup dialog, which allows the user to
  # edit a REST Method's endpoint name or the corresponding REST Resource's path.
  #
  # CONFIGURATION OPTIONS (all these options are optional)
  #  :tooltip_text - text that will be displayed in a tooltip over the text.
  #    default: 'Edit this endpoint's name'
  #  :link_text - text to be displayed as part of the link.
  #    default: 'edit'
  #  :style - any CSS inline styles that need to be applied to the text.
  #    default: ''
  #  :class - any CSS class that need to be applied to the text.
  #    default: nil
  def edit_endpoint_property_by_popup(rest_method, property="endpoint_name", *args)
    return '' unless rest_method.class.name == 'RestMethod'
    return '' unless %w{ endpoint_name resource_path }.include?(property.downcase)
    
    options = args.extract_options!
    
    # default config options
    options.reverse_merge!(:style => "",
                           :class => nil,
                           :link_text => "edit",
                           :tooltip_text => "Edit this endpoint's " + (property=="endpoint_name" ? "name":"path"))
    
    link_content = ''
    
    if BioCatalogue::Auth.allow_user_to_curate_thing?(current_user, rest_method)
      inner_html = content_tag(:span, options[:link_text])
      
      url_hash = {:controller => "rest_methods",
                  :action => (property=="endpoint_name" ? "edit_endpoint_name_popup" : "edit_resource_path_popup"),
                  :id => rest_method.id}

      fail_value = "alert('Sorry, an error has occurred.'); RedBox.close();"
      id_value = "edit_#{property}_for_#{rest_method.class.name}_#{rest_method.id}_redbox"
      
      redbox_hash = {:url => url_hash, 
                     :id => id_value, 
                     :failure => fail_value}
      link_content = link_to_remote_redbox(inner_html, redbox_hash, create_redbox_css_hash(options))
    end
    
    return link_content
  end
  
  
  # ========================================


  # This method will create a link to a popup dialog, which allows the user to
  # add more representations to the given RestMethod.
  #
  # CONFIGURATION OPTIONS (all these options are optional)
  #  :tooltip_text - text that will be displayed in a tooltip over the text.
  #    default: 'Add new representations to this endpoint'
  #  :link_text - text to be displayed as part of the link.
  #    default: 'Add new Representations'
  #  :style - any CSS inline styles that need to be applied to the text.
  #    default: ''
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
      inner_html += content_tag(:span, " " + options[:link_text])
      

      url_hash = {:controller => "rest_representations",
                  :action => "new_popup", 
                  :rest_method_id => method.id,
                  :http_cycle => http_cycle}

      fail_value = "alert('Sorry, an error has occurred.'); RedBox.close();"
      id_value = "new_representation_for_#{method.class.name}_#{method.id}_redbox"

      redbox_hash = {:url => url_hash,
                     :id => id_value, 
                     :failure => fail_value}
      link_content = link_to_remote_redbox(inner_html, redbox_hash, create_redbox_css_hash(options))
    else # NOT LOGGED IN
      inner_html = image_tag("add_inactive.png")
      inner_html += content_tag(:span, options[:link_text])
      
      link_content = link_to(inner_html, login_path, 
                             :class => options[:class], 
                             :style => options[:style], 
                             :title => tooltip_title_attrib("Login to #{options[:tooltip_text].downcase}"))
    end
    
    return link_content
  end
  
end
