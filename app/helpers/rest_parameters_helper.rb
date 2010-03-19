# BioCatalogue: app/helpers/rest_parameters_helper.rb
#
# Copyright (c) 2008, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details.

module RestParametersHelper
  include ApplicationHelper

  # This method will create a link to a popup dialog, which allows the user to
  # edit a parameter's constraint.
  #
  # CONFIGURATION OPTIONS (all these options are optional)
  #  :tooltip_text - text that will be displayed in a tooltip over the text.
  #    default: 'Edit constraint'
  #  :link_text - text to be displayed as part of the link.
  #    default: 'edit'
  #  :style - any CSS inline styles that need to be applied to the text.
  #    default: ''
  #  :class - any CSS class that need to be applied to the text.
  #    default: nil
  def edit_constraint_by_popup(parent_object, *args)
    return '' unless parent_object.class.name == 'RestParameter'
    
    options = args.extract_options!
    
    # default config options
    options.reverse_merge!(:style => "",
                           :class => nil,
                           :link_text => "edit",
                           :tooltip_text => "Edit constraint",
                           :constraint => nil,
                           :rest_method_id => nil)
                           
    return '' if options[:constraint].nil? || options[:rest_method_id].nil?
    
    link_content = ''

    method = RestMethod.find(options[:rest_method_id])
    
    if BioCatalogue::Auth.allow_user_to_curate_thing?(current_user, parent_object, :rest_method => method)
      inner_html = content_tag(:span, options[:link_text], :style => options[:style])
      
      fail_value = "alert('Sorry, an error has occurred.'); RedBox.close();"
      id_value = "edit_constraint_for_#{parent_object.class.name}_#{parent_object.id}_redbox"

      redbox_hash = {:url => create_url_hash(parent_object, options), 
                     :id => id_value, 
                     :failure => fail_value}
      link_content = link_to_remote_redbox(inner_html, redbox_hash, create_css_hash(options))
    end
    
    return link_content
  end
  
  # This method will create a link to a popup dialog, which allows the user to
  # edit a parameter's default value.
  #
  # CONFIGURATION OPTIONS (all these options are optional)
  #  :tooltip_text - text that will be displayed in a tooltip over the text.
  #    default: 'Edit default value'
  #  :link_text - text to be displayed as part of the link.
  #    default: 'edit'
  #  :style - any CSS inline styles that need to be applied to the text.
  #    default: ''
  #  :class - any CSS class that need to be applied to the text.
  #    default: nil
  def edit_default_value_by_popup(parent_object, *args)
    return '' unless parent_object.class.name == 'RestParameter'
    
    options = args.extract_options!
    
    # default config options
    options.reverse_merge!(:style => "",
                           :class => nil,
                           :link_text => "edit",
                           :tooltip_text => "Edit default vale",
                           :rest_method_id => nil)
                           
    return '' if options[:rest_method_id].nil?
    
    link_content = ''

    method = RestMethod.find(options[:rest_method_id])
    
    if BioCatalogue::Auth.allow_user_to_curate_thing?(current_user, parent_object, :rest_method => method)
      inner_html = content_tag(:span, options[:link_text], :style => options[:style])
            
      fail_value = "alert('Sorry, an error has occurred.'); RedBox.close();"
      id_value = "edit_constraint_for_#{parent_object.class.name}_#{parent_object.id}_redbox"

      
      redbox_hash = {:url => create_url_hash(parent_object, options, false), 
                     :id => id_value, 
                     :failure => fail_value}
      link_content = link_to_remote_redbox(inner_html, redbox_hash, create_css_hash(options))
    end
    
    return link_content
  end
  
  
  # ========================================
  
  
  private
  
  def create_css_hash(options)
    return {:style => options[:style],
            :class => options[:class],
            :alt => options[:tooltip_text],
            :title => tooltip_title_attrib(options[:tooltip_text]) }
  end
  
  def create_url_hash(parent_object, options, for_constraint=true)
    url_hash = {:controller => "rest_parameters",
                :id => parent_object.id,
                :rest_method_id => options[:rest_method_id] }
                  
    if for_constraint
      url_hash.merge!(:action => "edit_constraint_popup",
                      :constraint => options[:constraint])
    else
      url_hash.merge!(:action => "edit_default_value_popup")
    end
    
    return url_hash
  end
end