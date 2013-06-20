# BioCatalogue: app/helpers/rest_services_helper.rb
#
# Copyright (c) 2008, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details.

module RestServicesHelper
  include ApplicationHelper
    
  # This method will create a link to a popup dialog, which allows the user to
  # add more 'endpoints' or parameter to the given RestService or RestMethod respectively.
  #
  # CONFIGURATION OPTIONS (all these options are optional)
  #  :tooltip_text - text that will be displayed in a tooltip over the text.
  #    default: 'Add new endpoints to this service'
  #  :link_text - text to be displayed as part of the link.
  #    default: 'Add new endpoints'
  #  :style - any CSS inline styles that need to be applied to the text.
  #    default: ''
  #  :class - any CSS class that need to be applied to the text.
  #    default: nil
  def add_endpoints_by_popup(parent_object, *args)
    return '' unless parent_object.class.name =~ /RestService|RestMethod/
    create_endpoints = (parent_object.class.name=="RestService"? true:false)
    
    options = args.extract_options!
    
    # default config options
    options.reverse_merge!(:style => "",
                           :class => nil,
                           :link_text => "Add " + (create_endpoints ? "New Endpoints":"Input Parameters"),
                           :tooltip_text => (create_endpoints ? "Add new endpoints to this service" : 
                                                                "Add new input parameters to this endpoint"))

    default_styles = ""
    default_styles += "float: right; " unless options[:style].include?('float')
    default_styles += "font-weight: bold; " unless options[:style].include?('font-weight')
    
    options[:style] = default_styles + options[:style]

    link_content = ''
    
    if logged_in?
      inner_html = image_tag("add.png")
      inner_html += content_tag(:span, " " + options[:link_text])
      
      url_hash = {:controller => (create_endpoints ? "rest_resources":"rest_parameters"),
                  :action => "new_popup"}

      fail_value = "alert('Sorry, an error has occurred.'); RedBox.close();"
      
      if create_endpoints
        url_hash.merge!(:rest_service_id => parent_object.id)
        id_value = "new_endpoint_for_#{parent_object.class.name}_#{parent_object.id}_redbox"
      else
        url_hash.merge!(:rest_method_id => parent_object.id)
        id_value = "new_parameter_for_#{parent_object.class.name}_#{parent_object.id}_redbox"
      end

      redbox_hash = {:url => url_hash, :id => id_value, :failure => fail_value}
      link_content = link_to_remote_redbox(inner_html, redbox_hash, create_redbox_css_hash(options))
    else # NOT LOGGED IN
      inner_html = image_tag("add_inactive.png")
      inner_html += content_tag(:span, options[:link_text], :style => options[:style])
      
      link_content = link_to_remote_redbox(inner_html, login_path,
                             { :class => options[:class],
                             :style => options[:style], 
                             :title => tooltip_title_attrib("Login to #{options[:tooltip_text].downcase}") }.merge(:remote => true) )

    end
    
    return link_content
  end
  
  
  # ======================================== 
  
  
  # This method will create a link to a user profile: the user who added 'object'
  #
  # CONFIGURATION OPTIONS (all these options are optional)
  #  :style - any CSS inline styles that need to be applied to the text.
  #    default: ''
  #  :class - any CSS class that need to be applied to the text.
  #    default: nil
  def add_submitter_text(object, *args)
    return '' if object.nil? || object.submitter.nil?
    
    options = args.extract_options!
    
    # default config options
    options.reverse_merge!(:style => "",
                           :class => nil)

    options[:style] += "float: right; margin: 3px;" 
    
    actual_link_content = image_tag("user.png") + "<b>"
    actual_link_content += link_to(object.submitter_name, 
                                           user_path(User.find(object.submitter_id)),
                                           :title => "View #{object.submitter_name}'s profile.")
    actual_link_content += "</b>"
    
    link_content = content_tag(:span, 'Added by ' + actual_link_content, :style => options[:style])
    
    return link_content
  end


  # ========================================
  
  
  # This method will create a link to a popup dialog, which allows the user to
  # edit the base endpoint to a RestService
  #
  # CONFIGURATION OPTIONS (all these options are optional)
  #  :tooltip_text - text that will be displayed in a tooltip over the text.
  #    default: 'Add new endpoints to this service'
  #  :link_text - text to be displayed as part of the link.
  #    default: 'Add new endpoints'
  #  :style - any CSS inline styles that need to be applied to the text.
  #    default: ''
  #  :class - any CSS class that need to be applied to the text.
  #    default: nil
  def edit_base_endpoint_by_popup(service_deployment, *args)
    return '' unless service_deployment.class.name == 'ServiceDeployment'
    
    return '' unless BioCatalogue::Auth.allow_user_to_curate_thing?(current_user, service_deployment)
    
    rest_service = service_deployment.service_version.service_versionified
    return '' unless rest_service.class.name == "RestService"

    options = args.extract_options!
    
    # default config options
    options.reverse_merge!(:style => "",
                           :class => nil,
                           :link_text => "edit",
                           :tooltip_text => "Edit the base URL")

    options[:style] += "float: right; " unless options[:style].include?('float')
    options[:style] += "font-weight: bold; " unless options[:style].include?('font-weight')

    inner_html = image_tag("pencil.gif") + content_tag(:span, " " + options[:link_text])
    
    url_hash = {:controller => "rest_services", 
                :action => "edit_base_endpoint_by_popup", 
                :service_deployment_id => service_deployment.id }

    fail_value = "alert('Sorry, an error has occurred.'); RedBox.close();"
    id_value = "edit_base_endpoint_for_#{service_deployment.class.name}_#{service_deployment.id}_redbox"
    
    redbox_hash = {:url => url_hash, :id => id_value, :failure => fail_value}
    link_content = link_to_remote_redbox(inner_html, redbox_hash, create_redbox_css_hash(options).merge(:remote => true))
    
    return link_content
  end


  # ========================================
  
  
  # This generates a url template string which can be used to show how a REST Endpoint can be used.
  def create_url_template(rest_method)
    BioCatalogue::Util.generate_rest_endpoint_url_template(rest_method)
  end
  
  
  # ========================================
  
  
  # This method creates a CSS hash which can be used by redbox based on a list
  # of config 'options'
  def create_redbox_css_hash(options)
    return {:style => options[:style],
            :class => options[:class],
            :alt => options[:tooltip_text],
            :title => tooltip_title_attrib(options[:tooltip_text]) }
  end
end
