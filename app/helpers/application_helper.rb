# BioCatalogue: app/helpers/application_helper.rb
#
# Copyright (c) 2008, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details.

# Methods added to this helper will be available to all templates in the application.

require_dependency RAILS_ROOT + '/vendor/plugins/annotations/lib/app/helpers/application_helper'

module ApplicationHelper

  def markaby(&block)
    Markaby::Builder.new({}, self, &block)
  end
  
  # =================
  # Helpers for icons
  # -----------------

  def refresh_image
    image_tag "refresh.gif", :style => "vertical-align: middle;", :alt => "Refresh"
  end
  
  def expand_image(margin_left="0.3em")
    image_tag "expand.png", :style => "margin-left: #{margin_left}; vertical-align: middle;", :alt => 'Expand'
  end  

  #==================
  
  def controller_visible_name(controller_name)
    return "" if controller_name.blank?
    
    case controller_name.downcase
      when "stats"
        return "System Statistics"
      else
        return controller_name.humanize.titleize
    end
  end

  def flag_icon_from_country(country, text=country, style="margin-left: 0.5em;")
    return '' if country.blank?

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
      return flag_icon_from_country_code(code, text, style)
    else
      return ''
    end
  end

  def flag_icon_from_country_code(code, text=nil, style="margin-left: 0.5em;")
    code = "GB" if code.upcase == "UK"
    text = CountryCodes.country(code.upcase) if text.nil?
    return image_tag("flags/#{code.downcase}.png",
              :title => tooltip_title_attrib(text),
              :class => "flag",
              :style => "#{style}")
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
      case flag_pos.downcase
        when 'right'
          text = text + flag_icon_from_country_code(country_code)
        when 'left'
          text = flag_icon_from_country_code(country_code) + text
        else
          text = text + flag_icon_from_country_code(country_code)
      end
    end

    return text
  end

  def service_type_badges(service_types)
    html = ''

    unless service_types.blank?
      service_types.each do |s_type|
        html = html + content_tag(:span, s_type, :class => "service_type_badge", :style => "vertical-align: middle; margin-left: 1.5em;")
      end
    end

    return html
  end

  def service_location_flags(service)
    return '' if service.nil?

    html = ''

    service.service_deployments.each do |s_d|
      unless s_d.country.blank?
        html = html + flag_icon_from_country(s_d.country, s_d.location)
      end
    end

    return html
  end

  def help_icon_with_tooltip(help_text, delay=200)
    return image_tag("help_icon.png",
                     :title => tooltip_title_attrib(help_text, delay),
                     :style => "vertical-align:middle;")
  end

  def info_icon_with_tooltip(info_text, delay=200)
    return image_tag("info.png",
                     :title => tooltip_title_attrib(info_text, delay),
                     :style => "vertical-align:middle;")
  end
  
  
  # =======================
  # Helpers for Annotations
  # -----------------------
  
  # This method is used to generate an icon and/or link that will popup up an in page dialog box for the user to add an annotation (or mutliple annotations at once).
  #
  # It takes in the annotatable object that needs to be annotated and some options (all optional):
  #  :attribute_name - the attribute name for the annotation.
  #    default: nil
  #  :tooltip_text - text that will be displayed in a tooltip over the icon/text.
  #    default: 'Add annotation'
  #  :style - any CSS inline styles that need to be applied to the icon/text.
  #    default: ''
  #  :class - any CSS class that need to be applied to the icon/text.
  #    default: nil
  #  :link_text - text to be displayed as part of the link.
  #    default: ''
  #  :show_icon - specifies whether to show an icon or not to the left of the link text.
  #    default: true
  #  :icon_filename - the filename of the icon to use when in logged in (in the /public/images directory).
  #    default: 'add_annotation.gif'
  #  :icon_hover_filename - the filename of the icon to use for the mouseover event (in the /public/images directory).
  #    default: 'add_annotation_hover.gif'
  #  :icon_inactive_filename - the filename of the icon to use when not logged in (in the /public/images directory).
  #    default: 'add_annotation_inactive.gif'
  #  :show_not_logged_in_text - specifies whether to display some text (and an icon) when a user is not logged in, in place of the normal icon/text (will display something like: "log in to add description", where "log in" links to the login page).
  #    default: true
  #  :only_show_on_hover - specifies whether the add link (or log in link) should be hidden by default and only shown on hover. NOTE: this will only work when the link is inside a container with the class "annotations_container".
  #    default: true
  #  :multiple - specified whether multiple annotations need to be created at once (eg: for tags).
  #    default: false
  #  :multiple_separator - the seperator character(s) that will be used to seperate out multiple annotations from one value text.
  #    default: ','
  def annotation_add_by_popup_link(annotatable, *args)
     # Do options the Rails Way ;-)
    options = args.extract_options!
    # defaults:
    options.reverse_merge!(:attribute_name => nil,
                           :tooltip_text => 'Add annotation',
                           :style => '',
                           :class => nil,
                           :link_text => '',
                           :show_icon => true,
                           :icon_filename => 'add_annotation.gif',
                           :icon_hover_filename => 'add_annotation_hover.gif',
                           :icon_inactive_filename => 'add_annotation_inactive.gif',
                           :show_not_logged_in_text => true,
                           :only_show_on_hover => true,
                           :multiple => false,
                           :multiple_separator => ',')
    
    link_content = ''
    
    if logged_in?
      
      icon_filename_to_use = (options[:only_show_on_hover] == true ? options[:icon_hover_filename] : options[:icon_filename])
      
      link_inner_html = ''
      link_inner_html = link_inner_html + image_tag(icon_filename_to_use, :style => 'vertical-align:middle;margin-right:0.3em;') if options[:show_icon] == true
      link_inner_html = link_inner_html + content_tag(:span, options[:link_text], :style => "vertical-align: middle; text-decoration: underline;") unless options[:link_text].blank?

      url_options = { :annotatable_type => annotatable.class.name, :annotatable_id => annotatable.id }
      url_options[:attribute_name] = options[:attribute_name] unless options[:attribute_name].nil?
      url_options[:multiple] = options[:multiple] if options[:multiple]
      url_options[:separator] = options[:multiple_separator] if options[:multiple]
      
      link_class = (options[:only_show_on_hover] == true ? "active #{options[:class]}" : options[:class])

      link_content =  link_to_remote_redbox(link_inner_html,
                                   { :url => new_popup_annotations_url(url_options),
                                     :id => "annotate_#{annotatable.class.name}_#{annotatable.id}_#{options[:attribute_name]}_redbox",
                                     :failure => "alert('Sorry, an error has occurred.'); RedBox.close();" },
                                   { :style => "text-decoration: none; vertical-align: middle; #{options[:style]}",
                                     :class => link_class,
                                     :alt => options[:tooltip_text],
                                     :title => tooltip_title_attrib(options[:tooltip_text]) })
    
      # Add the greyed out inactive bit if required
      if options[:only_show_on_hover] == true
        inactive_span = content_tag(:span, 
                                    image_tag(options[:icon_filename], :style => 'vertical-align:middle;margin-right:0.3em;'), 
                                    :class => "inactive #{options[:class]}", 
                                    :style => "vertical-align: middle; #{options[:style]}")
        
        link_content = inactive_span + link_content
      end
    
    else
      # Not logged in...
      if options[:show_not_logged_in_text] == true
        icon_filename_to_use = options[:icon_inactive_filename]
        
        login_text = "Log in to add #{options[:attribute_name].nil? ? "annotation" : options[:attribute_name].downcase}"
        
        link_content_inner_html = image_tag(icon_filename_to_use, :style => 'vertical-align:middle;margin-right:0.3em;') if options[:show_icon] == true
        link_content_inner_html = link_content_inner_html + content_tag(:span, login_text, :style => "vertical-align: middle; text-decoration: underline;") unless options[:link_text].blank?
        
        link_class = (options[:only_show_on_hover] == true ? "active #{options[:class]}" : options[:class])
        
        link_content = link_to(link_content_inner_html, login_path, :class => link_class, :style => "text-decoration: none; vertical-align: middle; #{options[:style]}", :title => tooltip_title_attrib(login_text))
        
        # Add the greyed out inactive bit if required
        if options[:only_show_on_hover] == true
          inactive_span = content_tag(:span, 
                                    image_tag(icon_filename_to_use, :style => 'vertical-align:middle;margin-right:0.3em;'), 
                                    :class => "inactive #{options[:class]}", 
                                    :style => "vertical-align: middle; #{options[:style]}")
          
          link_content = inactive_span + link_content
        end
        
      end
    end
    
    return link_content 
  end

  # This method is used to generate an icon and/or link that will popup up an in page dialog box for the user to edit an annotation.
  #
  # It takes in the annotation object that needs to be edited and some options (all optional):
  #  :tooltip_text - text that will be displayed in a tooltip over the icon/text.
  #    default: 'Edit annotation'
  #  :style - any CSS inline styles that need to be applied to the icon/text.
  #    default: ''
  #  :link_text - text to be displayed as part of the link.
  #    default: 'edit'
  #  :show_icon - specifies whether to show the standard edit annotation icon or not.
  #    default: false
  #  :icon_filename - the filename of the icon to use when in normal view (in the /public/images directory).
  #    default: 'note_edit.png'
  def annotation_edit_by_popup_link(annotation, *args)
    # Do options the Rails Way ;-)
    options = args.extract_options!
    # defaults:
    options.reverse_merge!(:attribute_name => nil,
                           :tooltip_text => 'Edit annotation',
                           :style => '',
                           :link_text => 'edit',
                           :show_icon => false,
                           :icon_filename => 'note_edit.png')

    link_html = ''
    link_html = link_html + "<span style='vertical-align: middle; text-decoration: underline;'>#{options[:link_text]}</span>" unless options[:link_text].blank?
    link_html = image_tag(options[:icon_filename], :style => 'vertical-align:middle;margin-right:0.3em;') + link_html if options[:show_icon]

    return link_to_remote_redbox(link_html,
                                 { :url => edit_popup_annotation_url(annotation),
                                   :id => "edit_ann_#{annotation.id}_redbox",
                                   :failure => "alert('Sorry, an error has occurred.'); RedBox.close();" },
                                 { :style => "text-decoration: none; vertical-align: baseline; #{options[:style]}",
                                   :alt => options[:tooltip_text],
                                   :title => tooltip_title_attrib(options[:tooltip_text]) })
  end

  def annotation_add_info_text(attribute_name, annotatable)
    return '' if annotatable.nil?

    if attribute_name.blank?
      return "You are adding a custom annotation for the #{annotatable.class.name.titleize}: <b/>#{h(annotatable.annotatable_name)}</b>."
    else
      #return "You are adding a <b>#{attribute_name}</b> for the #{annotatable.class.name.titleize}: <b/>#{annotatable.annotatable_name}</b>"
      return "For #{annotatable.class.name.titleize}: <b/>#{h(annotatable.annotatable_name)}</b>."
    end

  end

  def annotation_add_value_label(attribute_name, multiple)
    label = ''

    if attribute_name.blank?
      label = "Value"
    else
      label = h(attribute_name)
    end

    # Pluralise if necessary...
    label = label.pluralize if multiple

    label = label + ":"

    return label
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

  def annotation_source_cssclass(annotation)
    return "annotation_source_#{annotation.source_type.downcase}"
  end

  def annotation_source_text(annotation, style='')
    return '' if annotation.nil?

    return content_tag(:p, :class => "annotation_source_text #{annotation_source_cssclass(annotation)}", :style => style) do
      "by #{annotation.source_type.titleize.downcase}: <b>#{link_to(h(annotation.source.annotation_source_name), annotation.source)}</b> (#{distance_of_time_in_words_to_now(annotation.created_at)} ago)"
    end
  end

  def annotation_prepare_description(desc, do_strip_tags, truncate_length, do_auto_link)
    return '' if desc.nil?

    desc = strip_tags(desc) if do_strip_tags
    desc = truncate(desc, :length => truncate_length) unless truncate_length.nil?
    desc = simple_format(desc) unless do_strip_tags
    desc = auto_link(desc, :all, :target => '_blank') if do_auto_link
    desc = white_list(desc)

    return desc
  end
  
  # =======================
  
  # ===============
  # Ratings helpers
  # ---------------
  
  # Gets the average rating for a specific item (has to be an annotatable item),
  # in the category specified.
  # The 'category' is should be the annotation attribute name for that category.
  def get_average_rating(annotatable, category)
    avg = 0.0
    
    anns = annotatable.annotations_with_attribute(category)
    
    unless anns.empty?
      # Note: this assumes that the values of the annotations are within constraints (ie: [1,2,3,4,5])
      avg = number_with_precision(anns.map{|x| x.value.to_i}.mean, :precision => 1)
    end
    
    return avg.to_f
  end
  
  # Gets the overall average ratings for a specific item (has to be an annotatable item).
  # This is the average of all the average ratings of all the categories of ratings for that annotatable model type.
  def get_overall_average_rating(annotatable)
    avg = 0.0
    
    ratings = [ ]
    
    BioCatalogue::Util.get_ratings_categories_config_for_model(annotatable.class).keys.each do |category|
      cat_avg = get_average_rating(annotatable, category)
      ratings << cat_avg if cat_avg > 0
    end
    
    avg = number_with_precision(ratings.mean, :precision => 1)
    
    return avg.to_f
  end
  
  def get_users_rating(annotatable, user, category)
    rating = 0
    
    rating_annotation = annotatable.annotations_with_attribute_and_by_source(category, user).first
    unless rating_annotation.nil?
      # Note: this assumes that the values of the annotations are within constraints (ie: [1,2,3,4,5])
      rating = rating_annotation.value.to_i
    end
    
    return rating
  end
  
  def get_count_of_ratings(annotatable, category)
    # Note: this assumes that the values of the annotations are within constraints (ie: [1,2,3,4,5])
    annotatable.annotations_with_attribute(category).length
  end
  
  def get_overall_count_of_ratings(annotatable)
    total_count = 0
    
    BioCatalogue::Util.get_ratings_categories_config_for_model(annotatable.class).keys.each do |category|
      total_count += get_count_of_ratings(annotatable, category)
    end
    
    return total_count
  end
  
  def rating_to_percentage(rating)
    return ((rating/5.to_f)*100).round
  end
  
  def render_star_rating_create_link(annotatable, category, rating_level, div_id)
    return link_to_remote(rating_level.to_s,
                          :url => "#{create_rating_url}?annotatable_type=#{annotatable.class.name}&annotatable_id=#{annotatable.id}&category=#{category}&rating=#{rating_level}",
                          :method => :post,
                          :update => { :success => div_id, :failure => '' },
                          :loading => "Element.show('ratings_spinner')",
                          :complete => "Element.hide('ratings_spinner')", 
                          :success => "new Effect.Highlight('#{div_id}', { duration: 0.5 });",
                          :failure => "Element.hide('ratings_spinner'); alert('Sorry, an error has occurred.');",
                          :html => { :class  => "#{rating_level_to_word(rating_level)}-stars", :title => "#{rating_level} star out of 5" } )
  end
  
  def rating_level_to_word(rating_level)
    word = ""
    
    case rating_level
      when 1
        word = "one"
      when 2
        word = "two"
      when 3
        word = "three"
      when 4
        word = "four"
      when 5
        word = "five"
    end
    
    return word
  end
  
  # ===============
  

  # ========================================
  # Code to help with remembering which tab
  # the  user was in after redirects etc.
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
  
  def service_latest_status_symbol(service)
    return '' if service.nil?
    
    if DISABLE_STATUS_CHECK 
      return ''
    end
    
    # Service latest status - using the only available deployment for now. In the future statuses will be displayed for each deployment
    latest_status = service.service_deployments[0].latest_online_status
    
    tooltip_text = "Service status: <b>#{latest_status.status}</b>"
    tooltip_text = tooltip_text + " (last checked #{distance_of_time_in_words_to_now(latest_status.created_at)} ago)" unless latest_status.status.downcase == "unchecked"
    
    # Unknown status means that a check was actually made but due to some condition, cannot conclude on the status
    # Possible causes are connection time out, connection refused
    if latest_status.status.downcase == "unknown"
      tooltip_text = tooltip_text + "<br> Message : #{latest_status.message} </br>"
    end
    
    return image_tag(onlooker_format(latest_status.status, 
                                     :online_img => "/images/accepted_48.png", 
                                     :offline_img => "/images/cancel_48.png", 
                                     :unknown_img => "/images/circle_orange.png", 
                                     :default_img => "/images/circle_blue.png"),
                                     :alt => latest_status.status, 
                                     :title => tooltip_title_attrib(tooltip_text))
  end
  
  def render_breadcrumbs_after_home
    render :partial => "breadcrumbs" if FileTest.exist?(File.join(RAILS_ROOT, 'app', 'views', controller.controller_name.downcase, '_breadcrumbs.html.erb'))
  end
  
end
