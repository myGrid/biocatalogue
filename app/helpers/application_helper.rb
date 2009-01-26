# BioCatalogue: app/helpers/application_helper.rb
#
# Copyright (c) 2008, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details.

# Methods added to this helper will be available to all templates in the application.

require_dependency RAILS_ROOT + '/vendor/plugins/annotations/lib/app/helpers/application_helper'

module ApplicationHelper
  
  def controller_visible_name(controller_name)
    controller_name.humanize.titleize
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
              :style => "vertical-align:middle; #{style}")
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
        html = html + content_tag(:span, s_type, :class => "service_type_badge", :style => "vertical-align: middle; margin-left: 0.8em;")
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
  
  # This method is used to generate an icon and/or link that will popup up an in page dialog box for the user to add an annotation (or mutliple annotations at once).
  # 
  # It takes in the annotatable object that needs to be annotated and some options (all optional):
  #  :attribute_name - the attribute name for the annotation.
  #    default: nil
  #  :tooltip_text - text that will be displayed in a tooltip over the icon/text.
  #    default: 'Add annotation'
  #  :style - any CSS inline styles that need to be applied to the icon/text.
  #    default: nil
  #  :link_text - text to be displayed as part of the link.
  #    default: ''
  #  :show_icon - specifies whether to show the standard annotate icon or not.
  #    default: true
  #  :icon_filename - the filename of the image in the /public/images directory.
  #    default: 'note_add.png'
  #  :show_not_logged_in_text - specifies whether to display some text when a user is not logged in, in place of the annotate icon/text (will display something like: "log in to add description", where "log in" links to the login page).
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
                           :style => nil,
                           :link_text => '',
                           :show_icon => true,
                           :icon_filename => 'note_add.png',
                           :show_not_logged_in_text => true,
                           :multiple => false, 
                           :multiple_separator => ',')
                           
    if logged_in?
      link_html = ''
      link_html = link_html + "<span style='vertical-align:middle'>#{options[:link_text]}</span>" unless options[:link_text].blank?
      link_html = image_tag(options[:icon_filename], :style => 'vertical-align:middle;margin-right:0.5em;') + link_html if options[:show_icon]
      
      url_options = { :annotatable_type => annotatable.class.name, :annotatable_id => annotatable.id }
      url_options[:attribute_name] = options[:attribute_name] unless options[:attribute_name].nil?
      url_options[:multiple] = options[:multiple] if options[:multiple]
      url_options[:separator] = options[:multiple_separator] if options[:multiple]
      
      return link_to_remote_redbox(link_html, 
                                   { :url => new_popup_annotations_url(url_options),
                                     :id => "annotate_#{annotatable.class.name}_#{annotatable.id}_#{options[:attribute_name]}_redbox",
                                     :failure => "alert('Sorry, an error has occurred.'); RedBox.close();" }, 
                                   { :style => options[:style], 
                                     :alt => options[:tooltip_text], 
                                     :title => tooltip_title_attrib(options[:tooltip_text]) })
    else
      if options[:show_not_logged_in_text] == true
        return content_tag(:span, "#{link_to("Log in", login_path)} to add #{options[:attribute_name].downcase}", :style => options[:style])
      else
        return ''        
      end
    end
  end
  
  # This method is used to generate an icon and/or link that will popup up an in page dialog box for the user to edit an annotation.
  # 
  # It takes in the annotation object that needs to be edited and some options (all optional):
  #  :tooltip_text - text that will be displayed in a tooltip over the icon/text.
  #    default: 'Edit annotation'
  #  :style - any CSS inline styles that need to be applied to the icon/text.
  #    default: nil
  #  :link_text - text to be displayed as part of the link.
  #    default: 'edit'
  #  :show_icon - specifies whether to show the standard edit annotation icon or not.
  #    default: false
  #  :icon_filename - the filename of the image in the /public/images directory.
  #    default: 'note_edit.png'
  def annotation_edit_by_popup_link(annotation, *args)
    # Do options the Rails Way ;-)
    options = args.extract_options!
    # defaults:
    options.reverse_merge!(:attribute_name => nil,
                           :tooltip_text => 'Edit annotation',
                           :style => nil,
                           :link_text => 'edit',
                           :show_icon => false,
                           :icon_filename => 'note_edit.png')
                           
    link_html = ''
    link_html = link_html + "<span style='vertical-align:middle'>#{options[:link_text]}</span>" unless options[:link_text].blank?
    link_html = image_tag(options[:icon_filename], :style => 'vertical-align:middle;margin-right:0.5em;') + link_html if options[:show_icon]
    
    return link_to_remote_redbox(link_html, 
                                 { :url => edit_popup_annotation_url(annotation),
                                   :id => "edit_ann_#{annotation.id}_redbox",
                                   :failure => "alert('Sorry, an error has occurred.'); RedBox.close();" }, 
                                 { :style => options[:style], 
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
      "by #{annotation.source_type.titleize.downcase}: <b>#{link_to(annotation.source.annotation_source_name, annotation.source)}</b> (#{distance_of_time_in_words_to_now(annotation.created_at)} ago)"
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
end
