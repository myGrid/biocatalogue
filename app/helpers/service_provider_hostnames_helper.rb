# BioCatalogue: app/helpers/service_provider_hostnames_helper.rb
#
# Copyright (c) 2008, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details.

module ServiceProviderHostnamesHelper

  # This method will create a link to a popup dialog, which allows the user to
  # assign the ServiceProviderHostname to a different ServiceProvider
  #
  # CONFIGURATION OPTIONS (all these options are optional)
  #  :tooltip_text - text that will be displayed in a tooltip over the text.
  #    default: 'Assign this hostname to a different service provider'
  #  :link_text - text to be displayed as part of the link.
  #    default: 'Reassign Service Provider'
  #  :style - any CSS inline styles that need to be applied to the text.
  #    default: ''
  #  :class - any CSS class that need to be applied to the text.
  #    default: nil
  def reassign_provider_by_popup(hostname, *args)    
    return '' unless BioCatalogue::Auth.allow_user_to_curate_thing?(current_user, hostname)
    
    return '' unless hostname.class == ServiceProviderHostname

    options = args.extract_options!
    
    # default config options
    options.reverse_merge!(:style => "",
                           :class => nil,
                           :link_text => "Reassign Service Provider",
                           :tooltip_text => "Assign this hostname to a different service provider")

    options[:style] += "float: right;" unless options[:style].include?("float")

    link_content = ''
    
    inner_html = content_tag(:span, options[:link_text])
    
    url_hash = {:controller => "service_provider_hostnames", 
                :action => "reassign_provider_by_popup",
                :id => hostname.id}

    fail_value = "alert('Sorry, an error has occurred.'); RedBox.close();"
    id_value = "edit_for_#{hostname.class.name}_#{hostname.id}_redbox"
    
    redbox_hash = {:url => url_hash, :id => id_value, :failure => fail_value}
    link_content = link_to_remote_redbox(inner_html, redbox_hash, create_redbox_css_hash(options))
    
    return link_content
  end

end
