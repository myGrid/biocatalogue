# BioCatalogue: app/helpers/tags_helper.rb
#
# Copyright (c) 2009, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

#require RAILS_ROOT + "/app/helpers/application_helper.rb"

module TagsHelper
  include ApplicationHelper
  
  # Generates a tag cloud from a list of annotations that are tags. 
  def generate_tag_cloud_from_annotations(tag_annotations, cloud_type, *args)
    generate_tag_cloud(BioCatalogue::Tags.annotations_to_tags_structure(tag_annotations), cloud_type, *args)
  end
  
  # This takes in a collection of 'tags' (in the format of the standardised tag data structure described in /lib/tags.rb)
  # and generates a tag cloud of either one of the following types:
  # - weighted
  # - flat
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
  # Options:
  #   :tag_cloud_style - additional styles to add to the tag_cloud div.
  #     default: ''
  #   :tag_style - additional styles to add to each tag element in the cloud.
  #     default: ''
  #   :min_font - the minimum font size (in px) to use.
  #     default: 10
  #   :max_font - the maximum font size (in px) to use.
  #     default: 30
  def generate_tag_cloud(tags, cloud_type, *args)
    return "" if tags.blank?
    
    cloud_type = cloud_type.downcase
    
    return "" unless [ "weighted", "flat" ].include?(cloud_type)
    
    # Do options the Rails Way ;-)
    options = args.extract_options!
    # defaults:
    options.reverse_merge!(:tag_cloud_style => "",
                           :tag_style => "",
                           :min_font => 10,
                           :max_font => 30)
    
    min_font = options[:min_font]
    max_font = options[:max_font]
      
    # Set up control variables for weighted tag cloud
    if cloud_type == "weighted"
      all_counts = tags.map{|t| t['count'].to_i } 
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
        when "weighted"
          min_font + font_range * ((Math.log(tag['count']) - minlog) / rangelog)
        when "flat"
          min_font
      end
        
      cloud << [tag['name'], font_size.to_i, tag['count']] 
    end
    
    output = ""
      
    unless cloud.blank?
      
      count = 0
      
      # Now build the tag cloud using Markaby (HTML generation library)...
      
      output = markaby do
        tag!(:div, :class => "tag_cloud", :style => options[:tag_cloud_style]) do 
          # <ul>
          ul do
            cloud.each do |tag_name, font_size, freq|
              # <li>
              li do
                # Special processing for ontological term URIs...
                if BioCatalogue::Tags.is_ontology_term_uri?(tag_name)
                  base_identifier_uri, keyword = BioCatalogue::Tags.split_ontology_term_uri(tag_name)
                  
                  inner_html = h(keyword)
                  title_text = "Full tag: #{h(tag_name)} <br/> Frequency: #{freq} times."
                  css_class = "ontology_term"
                # Otherwise, regular tags...
                else
                  inner_html = h(tag_name)
                  title_text = "Tag: #{h(tag_name)} <br/> Frequency: #{freq} times."
                  css_class = ""
                end
                
                # The URL is generated specially...
                a_href = BioCatalogue::Tags.generate_tag_show_uri(tag_name)
                
                tag!(:a,
                     :href => a_href,
                     :class => css_class,
                     :style => "font-size:#{font_size}px;  text-decoration: none; #{options[:tag_style]}",
                     :title => tooltip_title_attrib(title_text, 500)) { inner_html }
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
    
    return output
  end
end
