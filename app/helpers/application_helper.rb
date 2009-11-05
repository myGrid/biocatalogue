# BioCatalogue: app/helpers/application_helper.rb
#
# Copyright (c) 2009, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details.

# Methods added to this helper will be available to all templates in the application.

# ---
# Need to do this so that we play nice with the annotations and favourites plugin.
# THIS DOES UNFORTUNATELY MEAN THAT A SERVER RESTART IS REQUIRED WHENEVER CHANGES ARE MADE
# TO THIS FILE, EVEN IN DEVELOPMENT MODE.
require_dependency RAILS_ROOT + '/vendor/plugins/annotations/lib/app/helpers/application_helper'
require_dependency RAILS_ROOT + '/vendor/plugins/favourites/lib/app/helpers/application_helper'
# ---

module ApplicationHelper

  def markaby(&block)
    Markaby::Builder.new({}, self, &block)
  end
  
  # =================
  # Helpers for icons
  # -----------------
  
  def icon_filename_for(thing)
    case thing
      when :spinner
        "spinner.gif"
      when :delete
        "delete.png"
      when :delete_faded
        "delete_faded_darker.png"
      when :delete_faded_plus
        "delete_faded.png"
      when :refresh
        "refresh.gif"
      when :expand
        "expand.png"
      when :collapse
        "collapse.png"
      when :plus
        "plus.png"
      when :minus
        "minus.png"
      when :help
        "help_icon.png"
      when :info
        "info.png"
      when :search
        "search.png"
      when :submit_service
        "add.png"
      when :favourite, :favourites
        "favourite.png"
      when :favourite_faded, :favourites_none
        "favourite_faded.png"
      when :views
        "eye.png"
      when :views_none
        "eye_faded.png"
      when :annotations
        "note.png"
      when :user, :member, :annotation_source_member
        "user.png"
      when :registry, :annotation_source_registry
        "world_link.png"
      when :provider_document, :annotation_source_provider_document
        "page_white_code.png"
      when :agent, :annotation_source_agent
        "server_connect.png"
      when :curator, :annotation_source_curator
        "user_suit.png"
      when :twitter
        "twitter_icon.png"
      when :twitter_follow
        "twitter_follow_me.gif"
      when :atom
        "feed_icon.png"
      when :atom_large
        "feed_icon_large.png"
      when :tag_add
        "add_tag.gif"
      when :tag_add_hover
        "add_tag_hover.gif"
      when :tag_add_inactive
        "add_tag_inactive.gif"
      when :user_edit
        "user_edit.gif"
      when :arrow_forward
        "red_arrow.gif"
      when :download
        "arrow-down_16.png"
      when :open_in_new_window
        "page_go.png"
      else
        ''
    end
  end
  
  def delete_icon_faded_with_hover
    image_tag(icon_filename_for(:delete_faded_plus), :mouseover => icon_filename_for(:delete), :style => "vertical-align:middle;")
  end

  def refresh_image
    image_tag icon_filename_for(:refresh), :style => "vertical-align: middle;", :alt => "Refresh"
  end
  
  def expand_image(margin_left="0.3em")
    image_tag icon_filename_for(:expand), :style => "margin-left: #{margin_left}; vertical-align: middle;", :alt => 'Expand'
  end
  
  def collapse_image(margin_left="0.3em")
    image_tag icon_filename_for(:collapse), :style => "margin-left: #{margin_left}; vertical-align: middle;", :alt => 'Collapse'
  end
  
  def help_icon_with_tooltip(help_text, delay=200)
    return image_tag(icon_filename_for(:help),
                     :title => tooltip_title_attrib(help_text, delay),
                     :style => "vertical-align:middle;")
  end

  def info_icon_with_tooltip(info_text, delay=200)
    return image_tag(icon_filename_for(:info),
                     :title => tooltip_title_attrib(info_text, delay),
                     :style => "vertical-align:middle;")
  end
  
  def flag_icon_from_country(country, *args)
    return '' if country.blank?
    
    # Do options the Rails Way ;-)
    options = args.extract_options!
    # defaults:
    options.reverse_merge!(:text => country,
                           :class => "flag",
                           :style => "margin-left: 0.5em; vertical-align: middle;")

    code = ''

    if country.downcase == "great britain"
      code = "gb"
    elsif ["england", "wales", "scotland"].include?(country.downcase)
      code = country
    elsif country.length > 2
      code = CountryCodes.code(country)
    else
      code = country if CountryCodes.valid_code?(country)
    end

    #puts "code = " + code

    unless code.blank?
      return flag_icon_from_country_code(code, options)
    else
      return ''
    end
  end

  def flag_icon_from_country_code(code, *args)
    # Do options the Rails Way ;-)
    options = args.extract_options!
    # defaults:
    options.reverse_merge!(:text => nil,
                           :class => "flag",
                           :style => "margin-left: 0.5em; vertical-align: middle;")
                           
    code = "GB" if code.upcase == "UK"
    text = (options[:text].nil? ? h(CountryCodes.country(code.upcase)) : h(options[:text].to_s))
    return image_tag("flags/#{code.downcase}.png",
              :title => tooltip_title_attrib(text),
              :class => options[:class],
              :style => "#{options[:style]}")
  end

  #==================
  
  def sign_up_benefits_text
    output = ""
    
    output << content_tag(:p, :style => "font-weight: bold;") do
      "You get the following benefits by signing up for an account on the BioCatalogue:"
    end
    
    output << content_tag(:ul, :class => "simple_list") do
      "<li>Submit your own services</li>" +
      "<li>Annotate (describe, tag etc) and curate your services as well as any other services in the catalogue</li>" +
      "<li>Rate services</li>" +
      "<li>Favourite the services you use the most or like</li>" +
      "<li>Contact other members of the catalogue as well as service providers (coming soon)</li>"
    end
    
    return output
  end
  
  def controller_visible_name(controller_name)
    return "" if controller_name.blank?
    
    case controller_name.downcase
      when "stats"
        return "System Statistics"
      when "users"
        return "Members"
      else
        return controller_name.humanize.titleize
    end
  end

  def tooltip_title_attrib(text, delay=200)
    return "header=[] body=[#{text}] cssheader=[boxoverTooltipHeader] cssbody=[boxoverTooltipBody] delay=[#{delay}]"
  end

  def geo_loc_to_text(geo_loc, style='', flag=true, flag_pos='right')
    return '' if geo_loc.nil?
    return '' if geo_loc.country_code.nil?

    text = ''

    city, country = BioCatalogue::Util.city_and_country_from_geoloc(geo_loc)

    unless city.blank?
      text = text + "#{h(city)}, "
    end

    text = text + h(country) unless country.blank?

    country_code = h(geo_loc.country_code)

    if flag
      case flag_pos
        when :right
          text = text + flag_icon_from_country_code(country_code)
        when :left
          text = flag_icon_from_country_code(country_code) + text
        else
          text = text + flag_icon_from_country_code(country_code)
      end
    end

    return text
  end

  def submitter_link(submitter, icon_style='margin-right: 0.5em;')
    output = ""
    
    c = submitter.class.name
    c = "Member" if c == "User"
    
    output << '<span class="submitter_info">'
      
    output << image_tag(icon_filename_for(c.underscore.to_sym), :alt => "", :title => tooltip_title_attrib(c), :style => icon_style)
  
    output << case c
      when "Member"
        user_link_with_flag(submitter)
      else
        link_to(display_name(submitter), submitter) 
    end
    
    output << '</span>'
    
    return output
  end
  
  def user_link_with_flag(user)
    link_to(h(user.display_name), user_path(user), :style => "vertical-align: baseline") + flag_icon_from_country(user.country, :style => "vertical-align: middle; margin: 0 0.4em;")
  end
  
  def display_name(item)
    %w{ display_name title name }.each do |w|
      return eval("h(item.#{w})") if item.respond_to?(w)
      return item[w] if item.is_a?(Hash) && item.has_key?(w) 
    end
    return "#{item.class.name}_#{item.id}"
  end
  
  def separator_symbol_to_text(symbol, pluralize_text=false, show_symbol_after=true)
    text = case symbol.to_s
      when ' ' then "space"
      when ',' then "comma"
      when ';' then "semi-colon"
      else symbol
    end

    text = text.pluralize if pluralize_text

    text = "#{text} ('#{symbol}')" if show_symbol_after

    return text
  end
  
  
  # ========================================
  # Code to help with remembering which tab
  # the user was in after redirects etc.
  # ----------------------------------------

  # Note: the implementation of this method means that when it is used
  # it also resets the param to "false", thus the remembering of a tab is
  # only done in the one (current) request.
  # If more control than that is required (ie: being able to configure how long tab is remembered for),
  # then split into 2 different methods.
  def get_and_reset_use_tab_cookie_param_value
    #logger.info ""
    #logger.info "get_and_reset_use_tab_cookie_param_value called; before - session[:use_tab_cookie] = #{session[:use_tab_cookie]}"
    #logger.info ""
    
    value = session[:use_tab_cookie]
    value = value.blank? ? false : value
    
    session[:use_tab_cookie] = false
    
    #logger.info ""
    #logger.info "get_and_reset_use_tab_cookie_param_value called; after - session[:use_tab_cookie] = #{session[:use_tab_cookie]}"
    #logger.info ""
    
    return value
  end

  # ========================================
  
  # Calculate the overall status of the service from the set of check
  # that are available for this service. If any of the check did not 
  # pass, the overall status is set to warning.
  
  def service_latest_status_symbol(service)
    
    return '' if service.nil?
    
    if DISABLE_STATUS_CHECK 
      return ''
    end
    
    stats = []
   
    service.service_deployments.each do |dep|
      stats << dep.latest_endpoint_status
    end
    
    service.service_version_instances_by_type('SoapService').each do |soap|
      stats << soap.latest_wsdl_location_status
    end
    
    # overall status of the service is the status of this one test
    if stats.length == 1
      return service_test_status_symbol(stats[0], text_on_status_icon(stats[0], 'Service'))
    end
    
    # check if any of the test for this service returned a non
    # zero status, meaning something was not ok. If so, just return the warning symbol
    stats.each{ |r| 
      if r.result != 0 
        return service_test_status_symbol(r, text_on_status_icon(r, 'Service'))
      end }
    
    # every test was fine. Just return the status of the first one
    return service_test_status_symbol(stats[0], text_on_status_icon(stats[0], 'Service'))
    
  end
  
  #return a symbol according to the status of a test
  def service_test_status_symbol(tresult, attribute, history = false)
    status = "Unchecked"
    if tresult.result == 0
      status = "Online"
    elsif tresult.result == 1
      status = "Unknown"
#    elsif tresult.result == -1
#      status = "Unchecked"
    end
    
    #tooltip_text = "#{attribute} status: <b>#{status}</b>"
    tooltip_text = "#{attribute} : " 
    tooltip_text = tooltip_text + status if status.downcase == "unchecked"
    tooltip_text = tooltip_text + " (last checked #{distance_of_time_in_words_to_now(tresult.created_at)} ago)" unless status.downcase == "unchecked"
    
    if history
      return image_tag(onlooker_format(status, 
                                     :online_img => "/images/small-tick-sphere-50.png", 
                                     :offline_img => "/images/small-pling-sphere-50.png", 
                                     :unknown_img => "/images/small-pling-sphere-50.png", 
                                     :default_img => "/images/small-query-sphere-50.png"),
                                     :alt => status, 
                                     :title => tooltip_title_attrib(tooltip_text))
    end
    
    
    return image_tag(onlooker_format(status, 
                                     :online_img => "/images/tick-sphere-50.png", 
                                     :offline_img => "/images/pling-sphere-50.png", 
                                     :unknown_img => "/images/pling-sphere-50.png", 
                                     :default_img => "/images/query-sphere-50.png"),
                                     :alt => status, 
                                     :title => tooltip_title_attrib(tooltip_text))

  end
  
  def service_test_status_message(tresult)
    if tresult.result == 0
      return "Available :  #{distance_of_time_in_words_to_now(tresult.created_at)} ago "
    elsif tresult.result == 1
      return "Could not verify status :  #{distance_of_time_in_words_to_now(tresult.created_at)} ago "
    else
      return "Unchecked"
    end
  end
  
  # text to add to status icon. This text is shown on hovering over the icon
  def text_on_status_icon(status, attribute)
    if status.result == 0
      texts = {"Service" => "All checks were OK for this Service ",
               "Endpoint" => "Endpoint was available ",
               "Wsdl Location" => "Wsdl was found to be accessible "
                          }
                          
      return texts[attribute]
    end
    if status.result == 1
      texts = {"Service" => "Some checks were not OK for this Service. Could not confirm that <b> #{status.monitorable.property}</b> was available ",
               "Endpoint" => "We could not verify the status of this endpoint",
               "Wsdl Location" => "We could not confirm the accessibility of this WSDL"
                          }
                          
      return texts[attribute]
    end
    
    texts = {"Service" => "Service",
             "Endpoint" => "Endpoint",
               "Wsdl Location" => "WSDL Location"
                          }
                          
    return texts[attribute]
  end
  
  
  # Hack: helper method to check if the service is a soaplab
  # services. Checks for 'soaplab' in wsdl url
  def is_soaplab_service?(service)
    service.service_version_instances_by_type('SoapService').each do |soap|
      return true if soap.wsdl_location=~ /soaplab/
    end
    return false
  end

  # Hack: helper method to check if the service is a biomoby
  # service. Checks for 'biomoby' in wsdl url
  def is_biomoby_service?(service)
    service.service_version_instances_by_type('SoapService').each do |soap|
      return true if soap.wsdl_location =~ /biomoby/
    end
    return false
  end
  
  def render_breadcrumbs_after_home
    render :partial => "breadcrumbs" if FileTest.exist?(File.join(RAILS_ROOT, 'app', 'views', controller.controller_name.downcase, '_breadcrumbs.html.erb'))
  end
  
  def service_body_for_feed(service)
    output = ""
    
    unless service.nil?
      
      # Service Types
      output << content_tag(:p) do
        x = "<b>Service Type:</b> "
        service.service_types.each do |t|
          x << link_to(h(t), generate_include_filter_url(:t, t, :html))
        end
        x
      end
      
      # Name aliases
      name_annotations = BioCatalogue::Annotations.annotations_for_service_by_attribute(service, "name")
      unless name_annotations.blank?
        output << content_tag(:p) do
          x = "<b>Alternate names / aliases:</b> "
          x << name_annotations.map{|a| a.value}.to_sentence(:last_word_connector => ', ', :two_words_connector => ', ' )
          x
        end
      end
      
      # Categories
      
      output << "<p><b>Categories:</b></p>"
      
      category_annotations = service.annotations_with_attribute("category")
      
      if category_annotations.blank?
        output << content_tag(:p, "<i>Not categorised yet</i>", :style => "color:#666;")
      else
        output << content_tag(:p, :style => "margin-left: 20px;") do
          x = ''
          category_annotations.each do |ann|
            category = Category.find_by_id(ann.value)
            unless category.nil?
              x << link_to(h(category.name), services_path(:cat => "[#{category.id}]"))
              x << "&nbsp;&nbsp;"
            end
          end
          x
        end
      end
      
      output << link_to("<small>Help categorise this service...</small>", "#{service_url(service)}?categorise")
      
      # Provider
      output << content_tag(:p) do
        x = "<b>Provider:</b> "
        service.providers.each do |provider|
          x << link_to(h(provider.name), service_provider_path(provider))
        end
        x
      end
      
      # Location
      output << content_tag(:p) do
        x = "<b>Location:</b> "
        service.service_deployments.each do |s_d|
          unless (loc = s_d.location).blank?
            h(loc)
          end
        end
        x
      end
      
      # Submitter
      output << content_tag(:p) do
        x = "<b>Submitter / Source:</b> "
        x << (link_to(h(display_name(service.submitter)), service.submitter) + " (#{service.submitter_type.titleize})")
        x
      end
      
      # Endpoint
      output << content_tag(:p) do
        x = "<b>Endpoint:</b> "
        service.service_deployments.each do |s_d|
          x << link_to(h(s_d.endpoint), s_d.endpoint)
        end
        x
      end
      
      latest_version_instance = service.latest_version.service_versionified
      
      # WSDL Location
      unless latest_version_instance.nil?
        if latest_version_instance.is_a?(SoapService)
          output << content_tag(:p) do
            x = "<b>WSDL Location:</b> "
            x << link_to(h(latest_version_instance.wsdl_location), latest_version_instance.wsdl_location)
            x
          end
        end
      end
      
      # Descriptions
      
      output << "<p><b>Description(s):</b></p>"
      
      desc_annotations = latest_version_instance.annotations_with_attribute("description")
      
      if latest_version_instance.description.blank? and desc_annotations.blank?
        output << content_tag(:p, "<i>No descriptions yet</i>", :style => "color:#666;")
      else
        unless latest_version_instance.description.blank?
          output << content_tag(:p, "<i>from the provider's description document (#{distance_of_time_in_words_to_now(latest_version_instance.created_at)} ago):</i>")
          output << content_tag(:div, :style => "margin-left: 20px;") do
            annotation_prepare_description(latest_version_instance.description)
          end
        end
        desc_annotations.each do |ann|
          output << content_tag(:p) do
            x = "<i>"
            x << "by "
            x << "#{ann.source_type.titleize} "
            x << "#{link_to(h(ann.source.annotation_source_name), ann.source)} "
            x << "(#{distance_of_time_in_words_to_now(ann.created_at)} ago):"
            x << "</i>"
            x
          end
          output << content_tag(:div, :style => "margin-left: 20px;") do
            annotation_prepare_description(ann.value) 
          end
        end
      end
      
      output << link_to("<small>Do you know how this service works? If so, please help describe it...</small>", service)
      
      # Tags
      
      output << "<p><b>Tags:</b></p>"
      
      tag_annotations = BioCatalogue::Annotations.get_tag_annotations_for_annotatable(service)
      
      if tag_annotations.blank?
        output << content_tag(:p, "<i>No tags yet</i>", :style => "color:#666;")
      else
        output << content_tag(:p, :style => "margin-left: 20px;") do
          x = ''
          tag_annotations.each do |ann|
             x << link_to(BioCatalogue::Tags.split_ontology_term_uri(ann.value)[1], BioCatalogue::Tags.generate_tag_show_uri(ann.value))
             x << "&nbsp;&nbsp;"
          end
          x
        end
      end
      
      output << link_to("<small>Do you know something about this service? If so, please help tag it...</small>", service)
      
      output << "<br/><br/><br/>"
      
    end
    
    return output
  end
  
  def generic_render_show_hide_more_links(name, hidden_class_name, top=10)
    html = ""
    
    more_text = "Show all"
    less_text = "Show top #{top.to_s} only"
    
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
  
  def display_text_for_sortby(sortby)
    case sortby
      when "created"
        "Created At Date"
      when "updated"
        "Last Updated At Date"
      else
        ""
    end
  end
  
  def display_text_for_sortorder(sortorder)
    case sortorder
      when "asc"
        "Ascending"
      when "desc"
        "Descending"
    end
  end
  
end
