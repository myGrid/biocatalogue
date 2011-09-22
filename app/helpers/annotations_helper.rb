# BioCatalogue: app/helpers/annotations_helper.rb
#
# Copyright (c) 2008-2009, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details.

module AnnotationsHelper
  
  include ApplicationHelper
  
  def annotation_text_item_background_color
    #"#E9ECFF"
    "#EAEEFB"
  end
  
  def annotation_add_box_background_color
    "#E9ECFF"
  end     
  
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
  #    default: 'add_annotation.png'
  #  :icon_hover_filename - the filename of the icon to use for the mouseover event (in the /public/images directory).
  #    default: 'add_annotation_hover.png'
  #  :icon_inactive_filename - the filename of the icon to use when not logged in (in the /public/images directory).
  #    default: 'add_annotation_inactive.png'
  #  :show_not_logged_in_text - specifies whether to display some text (and an icon) when a user is not logged in, in place of the normal icon/text (will display something like: "log in to add description", where "log in" links to the login page).
  #    default: true
  #  :only_show_on_hover - specifies whether the add link (or log in link) should be hidden by default and only shown on hover. NOTE: this will only work when the link is inside a container with the class "annotations_container".
  #    default: true
  #  :multiple - specified whether multiple annotations need to be created at once (eg: for tags).
  #    default: false
  #  :multiple_separator - the seperator character(s) that will be used to seperate out multiple annotations from one value text.
  #    default: ','
  #
  # NOTE: for the hover over to work, the output of this needs to be wrapped in an element with the class 'add_option'.
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
                           :icon_filename => 'add_annotation.png',
                           :icon_hover_filename => 'add_annotation_hover.png',
                           :icon_inactive_filename => 'add_annotation_inactive.png',
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
                                    image_tag(options[:icon_inactive_filename], :style => 'vertical-align:middle;margin-right:0.3em;'), 
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
  #  :class - the CSS class to apply to the link.
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
                           :class => '',
                           :link_text => 'edit',
                           :show_icon => false,
                           :icon_filename => 'note_edit.png')

    link_html = ''
    
    options[:link_text] ||= 'edit'
    if options[:show_icon]
      link_html += image_tag(options[:icon_filename], :style => 'vertical-align:middle;margin-right:0.3em;') 
      link_html += "<span style='vertical-align: middle; text-decoration: underline;'>#{options[:link_text]}</span>"
    else
      link_html += options[:link_text]
    end

    return link_to_remote_redbox(link_html,
                                 { :url => edit_popup_annotation_url(annotation),
                                   :id => "edit_ann_#{annotation.id}_redbox",
                                   :failure => "alert('Sorry, an error has occurred.'); RedBox.close();" },
                                 { :style => (options[:show_icon] ? 
                                              "text-decoration: none; vertical-align: baseline; #{options[:style]}" : 
                                              options[:style]),
                                   :alt => options[:tooltip_text],
                                   :title => tooltip_title_attrib(options[:tooltip_text]),
                                   :class => options[:class] })
  end

  def annotation_add_info_text(attribute_name, annotatable)
    return '' if annotatable.nil?

    if attribute_name.blank?
      return "You are adding a custom annotation for the #{annotatable.class.name.titleize}: <b/>#{h(annotatable.annotatable_name)}</b>"
    elsif annotatable.class.name == "RestMethod"
      return "For Endpoint: <b/>#{h(annotatable.display_endpoint)}</b>"
    else
      return "For #{annotatable.class.name.titleize}: <b/>#{h(annotatable.annotatable_name)}</b>"
    end

  end

  def annotation_add_value_label(attribute_name, multiple)
    label = ''

    if attribute_name.blank?
      label = "Value"
    else
      label = h(attribute_name.humanize)
    end

    # Pluralise if necessary...
    label = label.pluralize if multiple

    label = label + ":"

    return label
  end

  def annotation_source_cssclass(annotation)
    return "annotation_source_#{annotation.source_type.downcase}"
  end
  
  def annotation_source_icon(source_type, style='margin-right: 0.3em;')
    return '' if source_type.nil?
    
    filename = ""
    title_attrib = ""
    
    case source_type
      when "ServiceProvider"
        style = 'margin-left: 0.2em; margin-right: 0.1em;'
        filename = icon_filename_for(:annotation_source_provider_document)
        title_attrib = tooltip_title_attrib("Provider's description doc")
      when "User"
        filename = icon_filename_for(:annotation_source_member)
        title_attrib = tooltip_title_attrib("Member")
      else
        filename = icon_filename_for("annotation_source_#{source_type.underscore}".to_sym)
        title_attrib = tooltip_title_attrib(source_type)
    end
    
    return image_tag(filename, :alt => "", :title => title_attrib, :style => style)
  end

  def annotation_source_text(annotation, style='')
    return '' if annotation.nil?

    return content_tag(:span, :class => "annotation_source_text #{annotation_source_cssclass(annotation)}", :style => style) do
      o = "<span>by </span>"
      o << annotation_source_icon(annotation.source_type)
      o << "#{link_to(h(annotation.source.annotation_source_name), annotation.source)} "
      o << user_role_badge(annotation.source.roles) if annotation.source_type == "User"
      o << "<span class='ago'>(#{distance_of_time_in_words_to_now(annotation.updated_at)} ago)</span>"
    end
  end

  def annotation_prepare_description(desc, do_strip_tags=false, truncate_length=nil, do_auto_link=true, do_simple_format=!do_strip_tags, do_white_list=true)
    return '' if desc.nil?

    desc = strip_tags(desc) if do_strip_tags
    desc = truncate(desc, :length => truncate_length) unless truncate_length.nil?
    desc = simple_format(desc) if do_simple_format
    desc = (do_white_list ? white_list(desc) : html_escape(desc))
    desc = auto_link(desc, :link => :all, :href_options => { :target => '_blank', :rel => 'nofollow' }) if do_auto_link

    return desc
  end
  
  def default_add_box_js_for_textarea(text_area_id, text_area_initial_height=100)
    "new Texpand('#{text_area_id}', {
      autoShrink: false,
      expandOnFocus: true,
      expandOnLoad: false,
      increment: 5,
      shrinkOnBlur: false,
      initialHeight: #{text_area_initial_height},
      onExpand: function(event) {
      }
    });
    new DefaultTextInput($('#{text_area_id}'));"
  end
  
end