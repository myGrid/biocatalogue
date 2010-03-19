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
  
end
