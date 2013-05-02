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
#require_dependency RAILS_ROOT + '/vendor/plugins/annotations/lib/app/helpers/application_helper'
require_dependency RAILS_ROOT + '/vendor/plugins/favourites/lib/app/helpers/application_helper'
# ---

module ApplicationHelper
  
  EXCLUDED_FLAG_CODES = BioCatalogue::Resource.EXCLUDED_FLAG_CODES

  def markaby(&block)
    Markaby::Builder.new({}, self, &block)
  end
  
  # =================
  # Helpers for icons
  # -----------------
  
  def icon_filename_for(thing)
    BioCatalogue::Resource.icon_filename_for(thing)
  end
  
  def generic_icon_for(thing, style='', tooltip_text=thing.to_s.titleize)
    opts = { }
    opts[:style] = "vertical-align: middle; #{style}"
    opts[:title] = tooltip_title_attrib(tooltip_text) unless tooltip_text.blank?
    opts[:alt] = (tooltip_text.blank? ? thing.to_s.titleize : tooltip_text)
    return image_tag(icon_filename_for(thing), opts)
  end
  
  def icon_faded_with_hover(type)
    image_tag(icon_filename_for("#{type.to_s}_faded".to_sym), :mouseover => icon_filename_for(type), :style => "vertical-align:middle;")
  end
  
  def refresh_image
    image_tag icon_filename_for(:refresh), :style => "vertical-align: middle;", :alt => "Refresh"
  end
  
  def expand_image(margin_left="0.3em", float="")
    float = "" unless %w{ inherit left right none }.include?(float.downcase.strip)
    
    style = (float.empty? ? "margin-left: #{margin_left}; vertical-align: middle;" :
                            "float: #{float}; margin-right: 5px; vertical-align: middle;")
    
    image_tag icon_filename_for(:expand), :style => style, :alt => 'Expand'
  end
  
  def collapse_image(margin_left="0.3em", float="")
    float = "" unless %w{ inherit left right none }.include?(float.downcase.strip)
    
    style = (float.empty? ? "margin-left: #{margin_left}; vertical-align: middle;" :
                            "float: #{float}; margin-right: 5px; vertical-align: middle;")

    image_tag icon_filename_for(:collapse), :style => style, :alt => 'Collapse'
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
  
  def feed_icon_tag(title, url, style='')
    alt_text = "Subscribe to <b>#{title}</b> feed"
    link_to image_tag(icon_filename_for(:atom), :alt => alt_text, :title => tooltip_title_attrib(alt_text), :style => "vertical-align: middle; padding: 0; #{style}"), url
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
      code = "GB"
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
    return "" if EXCLUDED_FLAG_CODES.include? code
    
    # Do options the Rails Way ;-)
    options = args.extract_options!
    # defaults:
    options.reverse_merge!(:text => nil,
                           :class => "flag",
                           :style => "margin-left: 0.5em; vertical-align: middle;")
                           
    text = (options[:text].nil? ? h(CountryCodes.country(code.upcase)) : h(options[:text].to_s))
    return image_tag(flag_icon_path(code),
              :title => tooltip_title_attrib(text),
              :class => options[:class],
              :style => "#{options[:style]}")
  end
  
  def flag_icon_path(code)
    BioCatalogue::Resource.flag_icon_path(code)
  end

  #==================
  
  def datetime(dt)
    return "" if dt.nil?
    return dt.to_s(:datetime24)
  end
  
  def sign_up_benefits_text
    output = ""
    
    output << content_tag(:p, :style => "font-weight: bold;") do
      "You get the following benefits by signing up for an account on the #{SITE_NAME}:"
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
        user_link_with_flag(:user => submitter)
      else
        link_to(display_name(submitter), submitter) 
    end
    
    output << '</span>'
    
    return output
  end
  
  # Generate a link to a user's profile
  # Either provide a :user => user OR 
  # :id => id, :display_name => display_name, :country => country. 
  def user_link_with_flag(*args)
    # Do options the Rails Way ;-)
    options = args.extract_options!
    # defaults:
    options.reverse_merge!(:user => nil,
                           :id => nil,
                           :display_name => nil,
                           :country => nil,
                           :roles => [ ])
    
    # Check that we have the basic minimum to process...
    if options[:user].blank? and (options[:id].blank? or options[:display_name].blank?)
      logger.error "ApplicationHelper#user_link_with_flag called with invalid options"
      return ""
    else
      decorations_style = "vertical-align: middle; margin-left: 0.4em;"
      
      if options[:user]
        return link_to(display_name(options[:user]), 
                       user_path(options[:user]), 
                       :style => "vertical-align: baseline") + 
                       flag_icon_from_country(options[:user].country, :style => decorations_style) +
                       user_role_badge(options[:user].roles, decorations_style)
      else
        return link_to(options[:display_name], 
                       user_path(options[:id]), 
                       :style => "vertical-align: baseline") + 
                       flag_icon_from_country(options[:country], :style => decorations_style) +
                       user_role_badge(options[:roles], decorations_style)
      end
    end
  end

  def user_role_badge(roles, style="vertical-align: middle; margin-left: 0.4em;")
    return "" if roles.blank?

    role_name = ''
    role_class = ''

    if roles.include? :admin
      role_name = "Admin"
      role_class = 'admin'
    elsif roles.include? :curator
      role_name = "Curator"
      role_class = 'curator'
    end

    return content_tag(:span, role_name, :style => style,
                        :class => "user_role_badge #{role_class}")
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
  
  # This takes into account the various idosyncracies and the data model 
  # to give you the best link to something. 
  def link_for_web_interface(item)
    url = url_for_web_interface(item)
    if url.blank?
      return display_name(item)
    else
      return link_to(display_name(item), url)
    end
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
  
  def service_latest_status_symbol(service, small=false)
    
    return '' if service.nil?
    
    if ENABLE_STATUS_DISPLAY 
      return status_symbol(service.latest_status, small)
    end
    return ''
  end
  
  def service_test_status_symbol(service_test, small=false)
    
    return '' if service_test.nil?
    
    if ENABLE_STATUS_DISPLAY 
      return status_symbol(service_test.latest_status, small)
    end
    return ''
    
#    #stat = tresult.service_test.latest_status
#    stat = BioCatalogue::MonitoringStatus::TestStatus.new(tresult)
#    tooltip_text = "#{attribute}  "  
#    tooltip_text = tooltip_text + " (last checked #{distance_of_time_in_words_to_now(tresult.created_at)} ago)" unless stat.status_label.downcase == "unchecked"
#    if history
#      return image_tag(stat.history_symbol_url, :alt => stat.message, :title => tooltip_title_attrib(tooltip_text))
#    end
#    return image_tag(stat.symbol_url, :alt => stat.message, :title => tooltip_title_attrib(tooltip_text))
  end

  def test_result_status_symbol(test_result, small=true)
    
    return '' if test_result.nil?
    
    if ENABLE_STATUS_DISPLAY 
      return status_symbol(test_result.status, small)
    end
    return ''
  end
  
  
  def status_symbol(status, small=false)
    last_checked_text = if status.last_checked.blank?
      ""
    else
      "<br/><span style='color:#666'>" + (small ? "Checked: " : "Last checked: ") + "#{distance_of_time_in_words_to_now(status.last_checked)} ago</span>"
    end
    
    
    
    tooltip_text = if small
      "Status: "
    else
      "Monitoring status: "
    end + "<b>#{status.label}</b><br/>#{status.message}#{last_checked_text}"
    
    symbol_filename = if small 
      status.small_symbol_filename
    else
      status.symbol_filename
    end
    
    return image_tag(symbol_filename, :alt => status.label, :title => tooltip_title_attrib(tooltip_text))
  end
    
  
  # Hack: helper method to check if the service is a soaplab
  # services. Checks for 'soaplab' in wsdl url
  def is_soaplab_service?(service)
    return true if service.soaplab_server
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
    if FileTest.exist?(File.join(RAILS_ROOT, 'app', 'views', controller.controller_name.downcase, '_breadcrumbs.html.erb')) 
      render :partial => "#{controller.controller_name.downcase}/breadcrumbs"
    end
  end
  
  def service_body_for_feed(service)
    output = ""
    
    unless service.nil?
      
      # Service Types
      output << content_tag(:p) do
        x = "<b>Service Type:</b> "
        service.service_types.each do |t|
          x << link_to(h(t), generate_include_filter_url(:t, t, "services", :html))
        end
        x
      end
      
      # Alternative names
      name_annotations = BioCatalogue::Annotations.annotations_for_service_by_attribute(service, "alternative_name")
      unless name_annotations.blank?
        output << content_tag(:p) do
          x = "<b>Alternate names:</b> "
          x << name_annotations.map{|a| a.value_content}.to_sentence(:last_word_connector => ', ', :two_words_connector => ', ' )
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
            category = nil
            category = ann.value if ann.value_type == "Category"
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
          x << link_to(display_name(provider), service_provider_path(provider))
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
      
      desc_annotations = latest_version_instance.annotations_with_attribute("description", true)
      
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
            annotation_prepare_description(ann.value_content) 
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
             x << link_to(BioCatalogue::Tags.split_ontology_term_uri(ann.value_content)[1], BioCatalogue::Tags.generate_tag_show_uri(ann.value_content))
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
  
  # This method will create an dropdown title (in the form of a link) 
  # which allows the components to be expanded or collapsed.
  #
  # If a block is passed then the contents of the block is used instead of :link_text config below.
  #
  # CONFIGURATION OPTIONS (all these options are optional)
  #  :link_text - text to be displayed as part of the link.
  #    default: update_element_id (the ID of the element to be expanded or collapsed)
  #  :link_style - any additional inline CSS styles that should be applied to the link tag.
  #    default: ''
  #  :style - any additional inline CSS styles that should be applied to the container span tag.
  #    default: ''
  #  :class - any CSS class that need to be applied to the container span tag.
  #    default: nil
  #  :icon_left_margin - the left margin of the expand / collapse icon.
  #    default: "5px"
  #  :icon_float - the CSS float value for the icon i.e. 'left', right', etc.  This OVERRIDES :icon_left_margin.
  #    default: ''
  def create_expand_collapse_link(update_element_id, *args, &block)
    return '' if update_element_id.blank?
    
    options = args.extract_options!
    # default config options
    options.reverse_merge!(:link_text => update_element_id,
                           :link_style => "",
                           :style => "", 
                           :class => nil,
                           :icon_left_margin => "5px",
                           :icon_float => "")
                           
    link_text = if block_given?
      capture(&block)
    else
      options[:link_text]
    end

    unless options[:icon_float].blank?
      expand_link = expand_image(options[:icon_left_margin], options[:icon_float]) + link_text
      collapse_link = collapse_image(options[:icon_left_margin], options[:icon_float]) + link_text
    else
      expand_link = link_text + expand_image(options[:icon_left_margin])
      collapse_link = link_text + collapse_image(options[:icon_left_margin])
    end

    expand_link_id = update_element_id + '_name_more_link'
    collapse_link_id = update_element_id + '_name_less_link'
    
    expand_link_content = link_to_function(expand_link, :id => expand_link_id, :style => "vertical-align: baseline;  #{options[:link_style]}") do |page| 
                            page.toggle expand_link_id, collapse_link_id
                            page.visual_effect :toggle_blind, update_element_id, :duration => '0.2'
                          end

    collapse_link_content = link_to_function(collapse_link, :id => collapse_link_id, :style => "display:none; vertical-align: baseline;  #{options[:link_style]}") do |page| 
                              page.toggle expand_link_id, collapse_link_id
                              page.visual_effect :toggle_blind, update_element_id, :duration => '0.2'
                            end 
                            
    span_content = expand_link_content + collapse_link_content
    
    content = content_tag(:span, span_content, :class => options[:class], :style => "vertical-align: baseline; #{options[:style]}")
    
    if block_given?
      return concat(content, block.binding)
    else
      return content
    end
  end
  
  def display_text_for_sort_by(sort_by)
    case sort_by
      when "created"
        "Created at date"
      when "modified"
        "Last modified at date"
      else
        ""
    end
  end
  
  def display_text_for_sort_order(sort_order)
    case sort_order
      when "asc"
        "Ascending"
      when "desc"
        "Descending"
    end
  end
  
  # Style can be :simple or :detailed
  def classify_time_span(dt, style=:simple)
    return "Unknown" if dt.nil?
    
    case style
      when :simple
        if dt > (Time.now - 7.days)
          return "Last 7 days"
        else
          return "Older"
        end
      when :detailed
        return "#{distance_of_time_in_words_to_now(dt).capitalize} ago"
      else
        return "Unknown"
    end
  end
  
  def show_last_search_box?
    return !(session[:last_search].blank? or controller.controller_name.downcase == "search" or controller.action_name.downcase == "search")
  end
 
  def resource_type_label_for_ui(resource_type)
    case resource_type
      when "SoapService", "SoapOperation", "SoapInput", "SoapOutput"
        return resource_type.gsub('Soap', 'SOAP ')
      when "RestService", "RestResource", "RestParameter", "RestRepresentation"
        return resource_type.gsub('Rest', 'REST ')
      when "RestMethod"
        return "REST Endpoint"
      else
        return resource_type.humanize
    end
  end
  
end
