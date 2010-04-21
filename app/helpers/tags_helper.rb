# BioCatalogue: app/helpers/tags_helper.rb
#
# Copyright (c) 2009, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

module TagsHelper
  include ApplicationHelper
  
  def help_text_for_tag_clouds
#    "Some of the tags in this tag cloud may be from ontologies, in which case they will be prepended with a namespace. <br/><br/>
#    e.g.: mygrid:DDBJ comes from the myGrid ontology. <br/><br/>
#    Hover over the tags to get more info."
    "Tags in purple are from ontologies / controlled vocabularies. <br/><br/>
    Tags in blue are regular keyword based tags."
  end
  
  # Generates a tag cloud from a list of annotations that are tags. 
  def generate_tag_cloud_from_annotations(tag_annotations, cloud_type, *args)
    generate_tag_cloud(BioCatalogue::Tags.annotations_to_tags_structure(tag_annotations), cloud_type, *args)
  end
  
  # This takes in a collection of 'tags' (in the format of the standardised tag data structure described in /lib/tags.rb)
  # and generates a tag cloud of either one of the following types:
  # - :weighted
  # - :flat
  #
  # The set of tags provided is assumed to be in the order that is to be shown in the cloud.
  #
  # This method is originally based on the one from the tag_cloud_helper plugin - 
  # http://github.com/sgarza/tag_cloud_helper/tree/master
  # but modified and adapted for BioCatalogue by Jits.
  #
  # Currently takes into account the following 'special' tags:
  # - Ontological term URIs (see /lib/tags.rb for the rules on these)
  #
  # Args options (all optional):
  #   :tag_cloud_style - additional styles to add to the tag_cloud div.
  #     default: ''
  #   :tag_style - additional styles to add to each tag element in the cloud.
  #     default: ''
  #   :min_font - the minimum font size (in px) to use.
  #     default: 10
  #   :max_font - the maximum font size (in px) to use.
  #     default: 30
  #   :allow_delete - if set to true then delete links will be placed next to each tag that the current user is allowed to delete.
  #     default: false
  #   :annotatable - required for the :allow_delete option. The current annotatable object that the tags apply to.
  #
  # IMPORTANT NOTE: The delete AJAX functionality depends on the parent container for the tag cloud having
  # an ID of "#{annotatable.class.name}_#{annotatable.id}_tag_cloud"
  def generate_tag_cloud(tags, cloud_type, *args)
    return "" if tags.blank?
    
    unless [ :weighted, :flat ].include?(cloud_type)
      logger.error("ERROR: Tried to build a tag cloud with an invalid cloud_type.")
      return ""      
    end
    
    # Do options the Rails Way ;-)
    options = args.extract_options!
    # defaults:
    options.reverse_merge!(:tag_cloud_style => "",
                           :tag_style => "",
                           :min_font => 10,
                           :max_font => 30,
                           :allow_delete => false,
                           :annotatable => nil)
    
    min_font = options[:min_font]
    max_font = options[:max_font]
      
    # Set up control variables for weighted tag cloud
    if cloud_type == :weighted
      all_counts = tags.map{|t| t['count'] } 
      maxlog = Math.log(all_counts.max)
      minlog = Math.log(all_counts.min)
      rangelog = maxlog - minlog;
      rangelog = 1 if maxlog==minlog
      font_range = max_font - min_font
    end
    
    separator_font_size = min_font + 2
    
    cloud = []

    tags.each do |tag|
      font_size = case cloud_type
        when :weighted
          min_font + font_range * ((Math.log(tag['count']) - minlog) / rangelog)
        when :flat
          min_font
      end
        
      cloud << [tag['name'], font_size.to_i, tag['count'], tag['submitters']] 
    end
    
    output = ""
      
    unless cloud.blank?
      
      count = 0
      
      # Now build the tag cloud using Markaby (HTML generation library)...
      
      output = markaby do
        tag!(:div, :class => "tag_cloud", :style => options[:tag_cloud_style]) do 
          # <ul>
          ul do
            cloud.each do |tag_name, font_size, freq, submitters|
              # <li>
              li do
                tag!(:span, :style => "font-size:#{font_size}px; #{options[:tag_style]}")  do
                  
                  # Special processing for ontological term URIs...
                  if BioCatalogue::Tags.is_ontology_term_uri?(tag_name)
                    namespace, keyword = BioCatalogue::Tags.split_ontology_term_uri(tag_name)
                    
                    #inner_html = "<span class='namespace'>#{h(namespace)}:</span><span>#{h(keyword)}</span>"
                    inner_html = h(keyword)
                    title_text = "Full tag: #{h(tag_name)} <br/> From: #{namespace} <br/> Frequency: #{freq} times"
                    css_class = 'ontology_term'
                  # Otherwise, regular tags...
                  else
                    inner_html = h(tag_name)
                    title_text = "Tag: #{h(tag_name)} <br/> Frequency: #{freq} times."
                    css_class = ''
                  end
                  
                  # The URL is generated specially...
                  a_href = BioCatalogue::Tags.generate_tag_show_uri(tag_name)
                  
                  tag!(:a,
                       :href => a_href,
                       :class => css_class,
                       :style => "text-decoration: none;",
                       :title => tooltip_title_attrib(title_text, 500)) { inner_html }
                  
                  # Add the option to delete the tag, if allowed (through the Auth module).
                  #
                  # IMPORTANT: The delete AJAX functionality depends on the parent container for the tag clouds having
                  # an ID of "#{annotatable.class.name}_#{annotatable.id}_tag_cloud"
                  if logged_in? and 
                     options[:allow_delete] and 
                     !options[:annotatable].nil? and 
                     !submitters.nil? and 
                     BioCatalogue::Auth.allow_user_to_curate_thing?(current_user, :tag, :tag_submitters => submitters) then
                     
                    link_to_remote(icon_faded_with_hover(:delete),
                                  :url => "#{tag_url(0, :tag_name => tag_name, :annotatable_type => options[:annotatable].class.name, :annotatable_id => options[:annotatable].id)}",
                                  :method => :delete,
                                  :update => { :success => "#{options[:annotatable].class.name}_#{options[:annotatable].id}_tag_cloud", :failure => '' },
                                  :loading => "Element.show('tags_spinner')",
                                  :complete => "Element.hide('tags_spinner')", 
                                  :success => "new Effect.Highlight('#{options[:annotatable].class.name}_#{options[:annotatable].id}_tags', { duration: 0.5 });",
                                  :failure => "Element.hide('tags_spinner'); alert('Sorry, an error has occurred.');",
                                  :html => { :title => tooltip_title_attrib("Delete this tag"), :style => "margin-left:0.4em;" },
                                  :confirm => "Are you sure you want to delete this tag?")
                  end
                  
                end
              end
            
              count += 1
          
              if count < cloud.length
                tag!(:li, " | ", :class => "faded_plus", :style => "font-size:#{separator_font_size}px;")
              end
            end
          end
        end
      end
      
    end
    
    return output.to_s
  end
end
