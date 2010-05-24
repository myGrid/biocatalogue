# BioCatalogue: lib/bio_catalogue/activity_feeds.rb
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# A helper module for activity feeds related functionality.
#
# Note that UI specific functionality should be done in views and/or UI helpers.
# This module is for more generic functionality.

module BioCatalogue
  module ActivityFeeds
    
    # A single point of call for getting a list of relevant +ActivityLog+ records 
    # for a particular activity feed. This can scoped to a particular object.
    #
    # Returns an +Array+ of +ActivityLog+ records that are sorted and limited to a certain number.
    #
    # Note: this method is cached. See the optional arguments below for settings.
    #
    # The following +location+ values are supported:
    #   :home
    #   :monitoring
    #   :service
    #
    # The following *optional* arguments are supported:
    #
    #   :scoped_object_type - the type of the object that the +ActivityLog+ records should be scoped for.
    #     Default:
    #       ''
    #   
    #   :scoped_object_id - the ID of the object that the +ActivityLog+ records should be scoped for.
    #     Default:
    #       0
    #
    #   :scoped_object - instead of providing the type and ID separately you can provide the object itself.
    #     Default:
    #       nil
    #    
    #   :style - the style of the activity feed that will be generated from these records. 
    #     Options:
    #       :simple
    #       :detailed
    #     Default: 
    #       :simple
    #
    #   :since - the last date at which the +ActivityLog+ records must stop.
    #     Default: 
    #       60
    #
    #   :items_limit - the maximum number of +ActivityLog+ records to return back, in total.
    #     Defaults:
    #       - For :simple style: 10
    #       - For :detailed style: 100
    #
    #   :query_limit - the limit on the number of items that any particular database query 
    #     should return. (Only use this option if really necessary).
    #     Defaults:
    #       - For :simple style: 500
    #       - For :detailed style: 1000
    #
    #   :cache_time - the maximum time to cache the results.
    #     Default:
    #       The value of the global constant HOMEPAGE_ACTIVITY_FEED_ENTRIES_CACHE_TIME
    #
    #   :cache_refresh - specifies whether a manual refresh of the cache should be done and fresh items returned.
    #     Default:
    #       false
    #
    def self.activity_logs_for(location, *args)
      return [ ] unless [ :home, :monitoring, :service ].include?(location)
      
      options = args.extract_options!
      
      # Defaults for options:
      
      options.reverse_merge!(:style => :simple, 
                             :since => 60.days.ago,
                             :scoped_object_type => '',
                             :scoped_object_id => 0,
                             :scoped_object => nil,
                             :cache_time => HOMEPAGE_ACTIVITY_FEED_ENTRIES_CACHE_TIME,
                             :cache_refresh => false)
      
      if options[:style] == :simple
        options.reverse_merge!(:query_limit => 500, 
                               :items_limit => 10)
      else
        options.reverse_merge!(:query_limit => 1000, 
                               :items_limit => 100)
      end
      
      scoped_object = options[:scoped_object]
      
      if scoped_object.nil?
        unless options[:scoped_object_type].blank? or options[:scoped_object_id].blank?
          scoped_object = options[:scoped_object_type].constantize.find_by_id(options[:scoped_object_id])
        end
      else
        options[:scoped_object_type] = scoped_object.class.name
        options[:scoped_object_id] = scoped_object.id
      end
      
      # Get 'em...
      
      activity_logs = nil
      
      begin
      
        cache_key = BioCatalogue::CacheHelper.cache_key_for(:activity_log_entries, location, options[:scoped_object_type], options[:scoped_object_id], options[:style])
      
        if options[:cache_refresh]
          Rails.cache.delete(cache_key)
        end
        
        # Try and get it from the cache...
        activity_logs = Rails.cache.read(cache_key)
        
        if activity_logs.nil?
          
          # It's not in the cache so get the values and store it in the cache...
          
          activity_logs = [ ]
          
          # Fetch the necessary ActivityLog entries...
  
          case location
            
            when :home
          
              # User activated
              activity_logs.concat ActivityLog.find(:all,
                :conditions => [ "action = 'activate' AND activity_loggable_type = 'User' AND created_at >= ?", options[:since] ],
                :order => "created_at DESC",
                :limit => options[:query_limit])
              
              # Services created
              activity_logs.concat ActivityLog.find(:all,
                :conditions => [ "action = 'create' AND activity_loggable_type = 'Service' AND created_at >= ?", options[:since] ],
                :order => "created_at DESC",
                :limit => options[:query_limit])
              
              # Annotations created
              activity_logs.concat ActivityLog.find(:all,
                :conditions => [ "action = 'create' AND activity_loggable_type = 'Annotation' AND created_at >= ?", options[:since] ],
                :order => "created_at DESC",
                :limit => options[:query_limit])
              
              # SoapServiceChanges created
              activity_logs.concat ActivityLog.find(:all,
                :conditions => [ "action = 'create' AND activity_loggable_type = 'SoapServiceChange' AND created_at >= ?", options[:since] ],
                :order => "created_at DESC",
                :limit => options[:query_limit])
              
              # Favourites created
              activity_logs.concat ActivityLog.find(:all,
                :conditions => [ "action = 'create' AND activity_loggable_type = 'Favourite' AND created_at >= ?", options[:since] ],
                :order => "created_at DESC",
                :limit => options[:query_limit])
              
            when :monitoring
              
              # Monitoring status changes
              activity_logs.concat ActivityLog.find(:all,
                :conditions => [ "action = 'status_change' AND activity_loggable_type = 'ServiceTest' AND created_at >= ?", options[:since] ],
                :order => "created_at DESC",
                :limit => options[:query_limit])
            
            when :service
            
              if scoped_object.is_a? Service
                
                associated_object_ids = scoped_object.associated_object_ids 
                
                # Services created
                activity_logs.concat ActivityLog.find(:all,
                  :conditions => [ "action = 'create' AND activity_loggable_type = 'Service' AND activity_loggable_id = ? AND created_at >= ?", options[:scoped_object_id], options[:since] ],
                  :order => "created_at DESC",
                  :limit => options[:query_limit])
                
                # Annotations created
                activity_logs.concat scoped_object.annotations_activity_logs(options[:since], options[:query_limit])
                
                # SoapServiceChanges created
                activity_logs.concat ActivityLog.find(:all,
                  :conditions => [ "action = 'create' AND activity_loggable_type = 'SoapServiceChange' AND referenced_type = 'SoapService' AND referenced_id IN (?) AND created_at >= ?", associated_object_ids["SoapServices"], options[:since] ],
                  :order => "created_at DESC",
                  :limit => options[:query_limit])
                
                # Favourites created
                activity_logs.concat ActivityLog.find(:all,
                  :conditions => [ "action = 'create' AND activity_loggable_type = 'Favourite' AND referenced_type = 'Service' AND referenced_id = ? AND created_at >= ?", options[:scoped_object_id], options[:since] ],
                  :order => "created_at DESC",
                  :limit => options[:query_limit])
                  
                # Monitoring status changes
                activity_logs.concat ActivityLog.find(:all,
                  :conditions => [ "action = 'status_change' AND activity_loggable_type = 'ServiceTest' AND referenced_type = 'Service' AND referenced_id = ? AND created_at >= ?", options[:scoped_object_id], options[:since] ],
                  :order => "created_at DESC",
                  :limit => options[:query_limit])
              
              end
          end
          
          # Reorder based on time
          activity_logs.sort! { |a,b| b.created_at <=> a.created_at }
          
          # Use only up to the limit and process these...
          activity_logs = activity_logs[0...options[:items_limit]]
          
          # Finally write it to the cache...
          Rails.cache.write(cache_key, activity_logs, :expires_in => options[:cache_time])
          
        end
      
      rescue Exception => ex
        BioCatalogue::Util.log_exception(ex, :error, "Failed to run 'BioCatalogue#ActivityFeeds.activity_logs_for location: #{location}")
      end
        
      return activity_logs || [ ]
    end
    
    # Builds an object cache of all the relevant objects referred 
    # to by a given collection of +ActivityLog+ records.
    #
    # For perf reasons this attempts to get as many of the objects 
    # in as little queries as possible. These include all the objects
    # referred to in the +ActivityLog+ entry and also the objects
    # referred to in any +Annotation+.
    #
    # The returned object cache can then be used when building up 
    # entries in the view.
    #
    # Returns a +Hash+ of +Hash+es where a single object can be
    # retrieved by:
    #   object_cache[model_type][id_as_string]
    #   E.g.: object_cache["Service"]["5"]
    def self.build_object_cache_for(activity_logs)
      return { } if activity_logs.blank?
      
      object_cache = nil
      
      # Create hashes that have default initialisers so that we don't have to
      # constantly keep checking for nil and initiliasing internal objects.
      object_cache = Hash.new { 
        |h,k| h[k] = Hash.new { 
          |x,y| x[y] = [ ] 
        } 
      }
      
      ids_map = Hash.new { |h,k| h[k] = [ ] }
      
      activity_logs.each do |al|
        ids_map[al.activity_loggable_type] << al.activity_loggable_id.to_s unless al.activity_loggable_type.blank? 
        ids_map[al.culprit_type] << al.culprit_id.to_s unless al.culprit_type.blank? 
        ids_map[al.referenced_type] << al.referenced_id.to_s unless al.referenced_type.blank?
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
        
      return object_cache
    end
    
  end
end