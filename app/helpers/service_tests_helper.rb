# BioCatalogue: app/helpers/service_test_helper.rb
#
# Copyright (c) 2009-2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details.

module ServiceTestsHelper
  
  def sort_li_class_helper(param, order)
    result = 'class="sortup"' if (params[:sort_by] == param && params[:sort_order] == order)
    result = 'class="sortdown"' if (params[:sort_by] == param && params[:sort_order] == reverse_order(order))  
    return result
  end
  
  def sort_link_helper(text, param, order)
    key   = param
    order = order
    order = reverse_order(params[:sort_order]) if params[:sort_by] == param
    params.delete(:page) # reset page
    options = {
      :url => {:action => 'index', :params => params.merge({:sort_by => key , :sort_order => order})}, #:page =>param[:page]
      :update => 'service_tests',
      :before => "Element.show('spinner')",
      :success => "Element.hide('spinner')"
      }
    html_options = {
      :title => "Sort by this field",
      :href => url_for(:action => 'index', :params => params.merge({:sort_by => key, :sort_order => order })) #:page => params[:page]
      }
    link_to(text, options, html_options, :remote => true)
  end
  
  def reverse_order(order)
    orders ={'asc' => 'desc', 'desc' => 'asc'}
    return orders[order]
  end
  
  # This method will create a link to a popup dialog, which allows the user to
  # add an 'endpoint' for (availability) monitoring.
  #
  # CONFIGURATION OPTIONS (all these options are optional)
  #  :tooltip_text - text that will be displayed in a tooltip over the text.
  #    default: 'Add a new endpoint for monitoring'
  #  :link_text - text to be displayed as part of the link.
  #    default: 'Add Monitoring Endpoint'
  #  :style - any CSS inline styles that need to be applied to the text.
  #    default: ''
  #  :class - any CSS class that need to be applied to the text.
  #    default: nil
  def add_monitoring_endpoint_by_popup_link(parent_service_instance, *args)
    return '' unless parent_service_instance.class == RestService
    
    return '' unless BioCatalogue::Auth.allow_user_to_curate_thing?(current_user, parent_service_instance)
    
    return '' unless parent_service_instance.service.has_capacity_for_new_monitoring_endpoint?
    
    options = args.extract_options!
    
    # default config options
    options.reverse_merge!(:style => "",
                           :class => nil,
                           :link_text => "Add Monitoring Endpoint",
                           :tooltip_text => "Add a new endpoint for monitoring")

    default_styles = ""
    default_styles += "float: right; " unless options[:style].include?('float')
    default_styles += "font-weight: bold; " unless options[:style].include?('font-weight')
    
    options[:style] = default_styles + options[:style]

    link_content = ''
    
    inner_html = image_tag("add.png")
    inner_html += content_tag(:span, " " + options[:link_text])
    
    url_hash = { :controller => "service_tests", :action => "new_url_monitor_popup", :service_id => parent_service_instance.service.id }
    
    fail_value = "alert('Sorry, an error has occurred.'); RedBox.close();"
    id_value = "new_monitoring_endpoint_for_#{parent_service_instance.class.name}_#{parent_service_instance.id}_redbox"
  
    redbox_hash = { :url => url_hash, :id => id_value, :failure => fail_value }
    
    link_content = link_to("redbox", inner_html, redbox_hash, create_redbox_css_hash(options), :remote => true)
    
    return link_content
  end
  
  # This method is used to generate an icon and/or link that will popup up an in page dialog box
  # for the user to edit an 'endpoint' for (availability) monitoring.
  #
  # It takes in the service test object that needs to be edited and some options (all optional):
  #  :tooltip_text - text that will be displayed in a tooltip over the icon/text.
  #    default: 'Edit'
  #  :style - any CSS inline styles that need to be applied to the icon/text.
  #    default: 'Update the URL used for monitoring by this service test'
  #  :class - the CSS class to apply to the link.
  #    default: '' 
  #  :link_text - text to be displayed as part of the link.
  #    default: 'edit'
  def monitoring_endpoint_edit_by_popup_link(service_test, *args)
    return '' unless service_test.class == ServiceTest
    return '' unless service_test.is_custom_endpoint_monitor? 
    
    return '' unless BioCatalogue::Auth.allow_user_to_curate_thing?(current_user, service_test.service)
    
    options = args.extract_options!
    
    # default config options
    options.reverse_merge!(:style => "",
                           :class => nil,
                           :link_text => "Edit",
                           :tooltip_text => "Update the URL used for monitoring by this service test")

    options[:style] += "float: right; " unless options[:style].include?('float')
    options[:style] += "font-weight: bold; " unless options[:style].include?('font-weight')

    link_content = ''
    
    inner_html = image_tag("pencil.gif") + content_tag(:span, " " + options[:link_text])
    
    url_hash = { :controller => "service_tests", :action => "edit_monitoring_endpoint_by_popup", :id => service_test.id }

    fail_value = "alert('Sorry, an error has occurred.'); RedBox.close();"
    id_value = "edit_for_#{service_test.class.name}_#{service_test.id}_redbox"
    
    redbox_hash = {:url => url_hash, :id => id_value, :failure => fail_value}
    link_content = link_to("redbox", inner_html, redbox_hash, create_redbox_css_hash(options), :remote => true)
    
    return link_content
  end

end
