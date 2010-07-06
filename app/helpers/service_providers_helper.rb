# BioCatalogue: app/helpers/service_providers_helper.rb
#
# Copyright (c) 2008, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details.

module ServiceProvidersHelper

  # This method will create a link to a popup dialog, which allows the user to
  # edit the details of a ServiceProvider
  #
  # CONFIGURATION OPTIONS (all these options are optional)
  #  :tooltip_text - text that will be displayed in a tooltip over the text.
  #    default: 'Give this service provider a new name'
  #  :link_text - text to be displayed as part of the link.
  #    default: 'Rename'
  #  :style - any CSS inline styles that need to be applied to the text.
  #    default: ''
  #  :class - any CSS class that need to be applied to the text.
  #    default: nil
  def edit_provider_by_popup(provider, *args)    
    return '' unless BioCatalogue::Auth.allow_user_to_curate_thing?(current_user, provider)
    
    return '' unless provider.class.name == "ServiceProvider"

    options = args.extract_options!
    
    # default config options
    options.reverse_merge!(:style => "",
                           :class => nil,
                           :link_text => "Rename",
                           :tooltip_text => "Give this service provider a new name")

    options[:style] += "float: right; " unless options[:style].include?('float')
    options[:style] += "font-weight: bold; " unless options[:style].include?('font-weight')

    link_content = ''
    
    inner_html = image_tag("pencil.gif") + content_tag(:span, " " + options[:link_text])
    
    url_hash = {:controller => "service_providers", 
                :action => "edit_by_popup",
                :id => provider.id}

    fail_value = "alert('Sorry, an error has occurred.'); RedBox.close();"
    id_value = "edit_for_#{provider.class.name}_#{provider.id}_redbox"
    
    redbox_hash = {:url => url_hash, :id => id_value, :failure => fail_value}
    link_content = link_to_remote_redbox(inner_html, redbox_hash, create_redbox_css_hash(options))
    
    return link_content
  end

end
