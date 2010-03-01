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
  #
  # Style can be :simple or :detailed
  def activity_entries_for_home(style=:simple, cache_refresh=false)
    results = [ ]
    
    options = { :days_limit => 60.days.ago } 
    if style == :simple
      options[:query_limit] = 500
      options[:items_limit] = 10
    else
      options[:query_limit] = 1000
      options[:items_limit] = 50
    end
              
    # Get relevant ActivityLog entries...
    
    al_items = nil
    
    benchmark "Retrieving all required activity log entries to build feed" do
      
      cache_key = BioCatalogue::CacheHelper.cache_key_for(:activity_log_entries, style)
    
      if cache_refresh
        Rails.cache.delete(cache_key)
      end
      
      # Try and get it from the cache...
      al_items = Rails.cache.read(cache_key)
      
      if al_items.nil?
        
        # It's not in the cache so get the values and store it in the cache...
        
        al_items = [ ]
        
        benchmark "Retrieving new users activity logs" do
          # Users activated
          al_items.concat ActivityLog.find(:all,
            :conditions => [ "action = 'activate' AND activity_loggable_type = 'User' AND created_at >= ?", options[:days_limit] ],
            :order => "created_at DESC",
            :limit => options[:query_limit])
        end
        
        benchmark "Retrieving new services activity logs" do
          # Services created
          al_items.concat ActivityLog.find(:all,
            :conditions => [ "action = 'create' AND activity_loggable_type = 'Service' AND created_at >= ?", options[:days_limit] ],
            :order => "created_at DESC",
            :limit => options[:query_limit])
        end
        
        benchmark "Retrieving new annotations activity logs" do
          # Annotations created
          al_items.concat ActivityLog.find(:all,
            :conditions => [ "action = 'create' AND activity_loggable_type = 'Annotation' AND created_at >= ?", options[:days_limit] ],
            :order => "created_at DESC",
            :limit => options[:query_limit])
        end
        
        benchmark "Sorting activity logs fetched" do
          # Reorder based on time
          al_items.sort! { |a,b| b.created_at <=> a.created_at }
        end
        
        # Use only up to the limit and process these...
        al_items = al_items[0...options[:items_limit]]
        
        # Finally write it to the cache...
        Rails.cache.write(cache_key, al_items, :expires_in => HOMEPAGE_ACTIVITY_FEED_ENTRIES_CACHE_TIME)
        
      end
      
    end
    
    # For perf reasons lets get as many objects as we can in as little queries 
    # and then cache these only use the cache when building up the entries...
    
    # Create hashes that have default initialisers so that we don't have to
    # constantly keep checking for nil and initiliasing internal objects. 
    
    object_cache = nil
    
    benchmark "Build object cache based on activity logs fetched" do
    
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
      
    end
      
    # We need to consider ordering of the grouped events!
    
    days_order = [ ]
      
    benchmark "Set up days_order (for the ordering of the grouped events)" do
    
      al_items.map { |a| a.created_at }.each do |d|
        c = classify_time_span(d, style)
        days_order << c unless days_order.include?(c)
      end
      
    end
  
    temp_results = Hash.new { |h,k| h[k] = [ ] }
    
    benchmark "Preparing the activity feed entries" do
    
      # Now prepare the entries    
      al_items.each do |al|
        if ["User", "Service", "Annotation"].include?(al.activity_loggable_type)
          s = activity_feed_entry_for(get_object_via_cache(al.activity_loggable_type, al.activity_loggable_id, object_cache), style, object_cache)
          data = [ s, al.activity_loggable_type.underscore.to_sym, al.created_at ]
          
          if s.blank?
            BioCatalogue::Util.yell "***"
            BioCatalogue::Util.yell "activity_feed entry was blank for activity_log record: #{al.inspect}"
            BioCatalogue::Util.yell "***"
          end
          
          temp_results[classify_time_span(al.created_at, style)] << data unless s.blank?
        end
      end
    
    end
    
    days_order.each do |d|
      results << { d => temp_results[d] }
    end
    
    return results
  end
  
  protected
  
  def activity_feed_entry_for(item, style, object_cache={})
    return "" if item.nil?
      
    output = ""
    
    benchmark "Building activity feed entry" do
    
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
          value_to_display = item.value
          
          # Special case for annotation values for certain kinds of attributes
          if item.attribute_name.downcase == "category"
            value_to_display = Category.find(item.value).try(:name)
          end
          
          unless value_to_display.blank? or item.attribute.nil? or annotatable.nil? or source.nil?
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
            
            if style == :detailed
              output << " - "
              output << content_tag(:div, :class => "box_annotations", :style => "margin-top: 0.1em;") do
                rounded_html(annotation_text_item_background_color, "#333", "99%") do
                  x = '<div class="text">'
                  x << annotation_prepare_description(value_to_display, true, 100, false)
                  x << '</div>'
                  x
                end
              end
            end
          end
          
      end
    
    end
    
    return output
  end
  
  def get_object_via_cache(obj_type, obj_id, object_cache)
    return (object_cache[obj_type][obj_id.to_s] || obj_type.constantize.find_by_id(obj_id))
  end
  
end