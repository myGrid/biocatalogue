# BioCatalogue: app/helpers/tags_helper.rb
#
# Copyright (c) 2009, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

#require RAILS_ROOT + "/app/helpers/application_helper.rb"

module TagsHelper
  include ApplicationHelper
  
  # Generates a tag cloud from a list of annotations that are tags. 
  def generate_tag_cloud_from_annotations(tag_annotations, *args)
    generate_tag_cloud(BioCatalogue::Tags.annotations_to_tags_structure(tag_annotations), *args)
  end
  
  # This takes in a collection of 'tags' (in the format of the standardised tag data structure described in /lib/tags.rb)
  # and generates a tag cloud.
  #
  # This method is based on the one from the tag_cloud_helper plugin - http://github.com/sgarza/tag_cloud_helper/tree/master
  # but modified and adapted for BioCatalogue by Jits.
  #
  # Currently takes into account the following 'special' tags:
  # - Ontological term URIs (enclosed in < >)
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
  def generate_tag_cloud(tags, *args)
    return "" if tags.blank?
      
    # Do options the Rails Way ;-)
    options = args.extract_options!
    # defaults:
    options.reverse_merge!(:tag_cloud_style => "",
                           :tag_style => "",
                           :min_font => 10,
                           :max_font => 30)
    
    # Sort by count
    tags.sort! { |a,b| b["count"].to_i <=> a["count"].to_i }
    
    maxlog = Math.log(tags.first['count'])
    minlog = Math.log(tags.last['count'])
    rangelog = maxlog - minlog;
    rangelog = 1 if maxlog==minlog
    min_font = options[:min_font]
    max_font = options[:max_font]
    font_range = max_font - min_font
    
    separator_font_size = min_font + 2
    
    # Sort tags alphabetically
    tags = BioCatalogue::Tags.sort_tags_alphabetically(tags)
    
    cloud = []

    tags.each do |tag|
      font_size = min_font + font_range * ((Math.log(tag['count']) - minlog) / rangelog)
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
                  base_ontology_uri, ontology_term = BioCatalogue::Tags.split_ontology_term_uri(tag_name)
                  
                  inner_html = h(ontology_term)
                  a_href = tag_show_url(:tag => URI::escape(ontology_term)) + "?#{base_ontology_uri.to_query("base_ontology")}"
                  title_text = "Full tag: #{h(tag_name)} <br/> Frequency: #{freq} times."
                  css_class = "ontology_term"
                # Otherwise, regular tags...
                else
                  inner_html = h(tag_name)
                  a_href = tag_show_url(:tag => URI::escape(tag_name))
                  title_text = "Tag: #{h(tag_name)} <br/> Frequency: #{freq} times."
                  css_class = ""
                end
                
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
