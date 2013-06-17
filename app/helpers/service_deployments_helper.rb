# BioCatalogue: app/helpers/service_deployments_helper.rb
#
# Copyright (c) 2008, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details.

module ServiceDeploymentsHelper

  def edit_location_by_popup(service_deployment, *args)

    return '' unless service_deployment.class.name == 'ServiceDeployment'

    return '' unless BioCatalogue::Auth.allow_user_to_curate_thing?(current_user, service_deployment)

    options = args.extract_options!

    # default config options
    options.reverse_merge!(:style => "",
                           :class => nil,
                           :link_text => "edit",
                           :tooltip_text => "Edit the location")

    options[:style] += "float: right; " unless options[:style].include?('float')
    options[:style] += "font-weight: bold; " unless options[:style].include?('font-weight')

    inner_html = image_tag("pencil.gif") + content_tag(:span, " " + options[:link_text])

    url_hash = {:controller => "service_deployments",
                :action => "edit_location_by_popup",
                :id => service_deployment.id }

    fail_value = "alert('Sorry, an error has occurred.'); RedBox.close();"
    id_value = "edit_location_for_#{service_deployment.class.name}_#{service_deployment.id}_redbox"

    redbox_hash = {:url => url_hash, :id => id_value, :failure => fail_value}
    link_content = link_to_remote_redbox(inner_html, redbox_hash, create_redbox_css_hash(options).merge(:remote => true))

    return link_content
  end

end
