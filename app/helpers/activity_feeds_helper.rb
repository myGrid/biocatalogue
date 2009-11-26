# BioCatalogue: app/helpers/application_helper.rb
#
# Copyright (c) 2009, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details.

# Methods added to this helper will be available to all templates in the application.

module ActivityFeedsHelper
  
  include ApplicationHelper
  
  # Returns something like:
  #   [ { "Today" => [ [ "text", :service, DateTime ], [ ... ], ... ] },
  #     { "Yesterday" => [ [ "text", :user, DateTime ], [ ... ], ... ] },
  #     { "4 weeks ago" => [ [ "text", :annotation, DateTime ], [ ... ], ... ] } ] 
  def activity_entries_for_home
    results = [ ]
    
    options = { :items_limit => 30,
                :days_limit => 60.days.ago }
              
    # Get relevant ActivityLog entries...
    
    al_items = [ ]

    # Users activated
    al_items.concat ActivityLog.find(:all,
      :conditions => [ "action = 'activate' AND activity_loggable_type = 'User' AND created_at >= ?", options[:days_limit] ],
      :limit => options[:items_limit],
      :order => "created_at DESC")
    
    # Services and Annotations created
    al_items.concat ActivityLog.find(:all,
      :conditions => [ "action = 'create' AND activity_loggable_type IN ('Service','Annotation') AND created_at >= ?", options[:days_limit] ],
      :limit => options[:items_limit],
      :order => "created_at DESC")
    
    # Reorder based on time
    al_items.sort { |a,b| b.created_at <=> a.created_at }
    
    # Use only up to the limit and process these...
    al_items = al_items[0...options[:items_limit]]
    
    # For perf reasons lets get as many objects as we can in as little queries 
    # and then cache these only use the cache when building up the entries...
    
    # Create hashes that have default initialisers so that we don't have to
    # constantly keep checking for nil and initiliasing internal objects. 
    
    object_cache = Hash.new { 
      |h,k| h[k] = Hash.new { 
        |x,y| x[y] = [ ] 
      } 
    }
    
    ids_map = Hash.new { |h,k| h[k] = [ ] }
    
    al_items.each do |al|
      ids_map[al.activity_loggable_type] << al.activity_loggable_id.to_s unless al.activity_loggable_type.nil? 
      ids_map[al.culprit_type] << al.culprit_id.to_s unless al.culprit_type.nil? 
      ids_map[al.referenced_type] << al.referenced_id.to_s unless al.referenced_type.nil?
    end
    
    # First annotations, so we can pick out more useful things...
    
    Annotation.find_all_by_id(ids_map["Annotation"]).each do |a|
      object_cache["Annotation"][a.id.to_s] = a
    end
    
    object_cache["Annotation"].values.each do |a|
      ids_map[a.annotatable_type] << a.annotatable_id.to_s
      ids_map[a.source_type] << a.source_id.to_s
    end
    
    # Now get the rest of the objects required and store in cache...
    ids_map.each do |k,v|
      unless k == "Annotation"
        k.constantize.find_all_by_id(v).each do |a|
          object_cache[k][a.id.to_s] = a
        end
      end
    end
    
    # We need to consider ordering of the grouped events!
    
    days_order = [ ]
    al_items.map { |a| a.created_at }.sort { |a,b| b <=> a }.each do |d|
      c = classify_day(d)
      days_order << c unless days_order.include?(c)
    end
    
    temp_results = Hash.new { |h,k| h[k] = [ ] }
    
    # Now prepare the entries    
    al_items.each do |al|
      if ["User", "Service", "Annotation"].include?(al.activity_loggable_type)
        s = activity_feed_entry_for(get_object_via_cache(al.activity_loggable_type, al.activity_loggable_id, object_cache), object_cache)
        data = [ s, al.activity_loggable_type.underscore.to_sym, al.created_at ]
        temp_results[classify_day(al.created_at)] << data unless s.blank?
      end
    end
    
    days_order.each do |d|
      results << { d => temp_results[d] }
    end
    
    return results
  end
  
  protected
  
  def activity_feed_entry_for(item, object_cache={})
    return "" if item.nil?
      
    output = ""
    
    case item
      when User
        
        output << link_to(display_name(item), item)
        output << content_tag(:span, " joined", :class => "activity_feed_action")
        output << " the BioCatalogue"
        
      when Service
        
        submitter = get_object_via_cache(item.submitter_type, item.submitter_id, object_cache)
        
        unless submitter.nil?
          output << link_to(display_name(submitter), submitter)
          output << content_tag(:span, " registered", :class => "activity_feed_action")
          output << " a new Service: "
          output << link_to(display_name(item), item)
        end
        
      when Annotation
        
        annotatable = get_object_via_cache(item.annotatable_type, item.annotatable_id, object_cache)
        source = get_object_via_cache(item.source_type, item.source_id, object_cache)
        
        unless item.attribute.nil? or annotatable.nil? or source.nil?
          subject_name = case item.annotatable_type
            when "Service", "ServiceDeployment", "ServiceVersion", "SoapService", "RestService"
              "Service"
            else
              item.annotatable_type.titleize
          end
        
          output << link_to(display_name(source), source)
          output << content_tag(:span, " added", :class => "activity_feed_action")
          output << " a #{item.attribute_name.humanize.downcase} annotation to #{subject_name}: "
          
          link = link_for_web_interface(annotatable)
          
          output << (link || display_name(annotatable))
          output << " - "
          output << content_tag(:div, :class => "box_annotations", :style => "margin-top: 0.1em;") do
            rounded_html(annotation_text_item_background_color, "#333", "99%") do
              x = '<div class="text">'
              x << annotation_prepare_description(item.value, true, 100, false)
              x << '</div>'
              x
            end
          end
        end
        
    end
    
    return output
  end
  
  def classify_day(dt)
#    if dt > (Time.now - 1.day)
#      return "Today"
#    elsif dt > (Time.now - 2.days)
#      return "Yesterday"
#    else
      return "#{distance_of_time_in_words_to_now(dt).capitalize} ago"
#    end
  end
  
  def get_object_via_cache(obj_type, obj_id, object_cache)
    return (object_cache[obj_type][obj_id.to_s] || obj_type.constantize.find_by_id(obj_id))
  end
  
end