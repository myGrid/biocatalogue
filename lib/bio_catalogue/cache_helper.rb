# BioCatalogue: lib/bio_catalogue/cache_helper.rb
#
# Copyright (c) 2009, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# Helper module to provide functions to aid in caching.

module BioCatalogue
  module CacheHelper
    
    NONE_VALUE = "<none>".freeze
    
    def self.set_base_host(base_host)
      silence_warnings { CacheHelper::Expires.const_set "BASE_HOST", base_host } unless defined? CacheHelper::Expires.BASE_HOST
    end
    
    def self.cache_key_for(type, *args)
      case type
        when :metadata_counts_for_service
          "metadata_counts_for_service_#{args[0]}"
        when :children_of_category
          "children_of_category_#{args[0]}"
        when :services_count_for_category
          "services_count_for_category_#{args[0]}"
      end
    end
    
    def self.setup_caches
      Util.say("Setting up caches...")
      
      Util.say("memcache-client version = #{MemCache::VERSION}")
      
      # Read the cache settings from config/memcache.yml.
      # NOTE: to disable memcache for any environment, leave the "servers: " part blank.
      # IMPORTANT: it's absolutely crucial that you leave a space after "servers:"
      # otherwise the app will refuse to start!
      
      config_path = File.join(RAILS_ROOT, "config", "memcache.yml")
      
      if File.exist?(config_path)
        config = YAML.load(IO.read(config_path))[RAILS_ENV]
        
        if config and !config['servers'].blank?
          
          begin
          
            # We need to set up both the ActionController cache and the Rails.cache to use the same memcache client.
            # Unfortunately there is no easy way to do this! I've had to dig into the Rails source code
            # to figure out the best way of doing this...
            
            memcache_servers = config['servers']
            config.delete('servers')
            
            memcache_options = {
              :readonly    => false,
              :multithread => true,
              :failover    => true,
              :timeout     => 1,
              :logger      => Rails.logger,
              :no_reply    => false,
            }.update(config)
            
            memcache_client1 = MemCache.new(memcache_servers, memcache_options)
            memcache_client2 = MemCache.new(memcache_servers, memcache_options)
            
            Util.say("memcache_client servers: #{memcache_client1.servers.inspect}")
            
            # Set up cache objects for cache-money
            if ENABLE_CACHE_MONEY
              $memcache = memcache_client1
              $local = Cash::Local.new($memcache)
              $lock = Cash::Lock.new($memcache)
              $cache = Cash::Transactional.new($local, $lock)
            end 
            
            # Set the global CACHE variable...
            # BUT this MUST NOT be used directly, use Rails.cache instead.
            silence_warnings { Object.const_set "CACHE", memcache_client2 }
            
            # Create the ActiveSupport::Cache::MemCacheStore which is what Rail will use...
            rails_memcache_client = ActiveSupport::Cache::MemCacheStore.new(memcache_servers, memcache_options)
            
            # Set the Rails.cache
            silence_warnings { Object.const_set "RAILS_CACHE", rails_memcache_client }
            
            # Set the ActionController cache
            ActionController::Base.class_eval do
              @@cache_store = rails_memcache_client
            end
          
          rescue Exception => ex
            Rails.logger.error("Error whilst setting up caches. Exception: #{ex.class.name} - #{ex.message}")
            Rails.logger.error(ex.backtrace)
          end
          
        else
          Util.say("No cache defined for #{RAILS_ENV} environment. That's okay, an in memory store will be used instead for caching...")
        end
        
      else
        Util.say("Missing config file: config/memcache.yml. Use the settings from config/memcache.yml.pre. Otherwise, an in memory store will be used instead for caching...")
      end
    end
    
    def self.reset_caches
      $memcache.reset if ENABLE_CACHE_MONEY and defined?($memcache) and !$memcache.nil?
      
      CACHE.reset if defined?(CACHE) and !CACHE.nil?
      
      if defined?(RAILS_CACHE) and !RAILS_CACHE.nil?
        RAILS_CACHE.instance_eval do 
          @data.reset
        end
      end
    end
    
    module Expires
      require 'action_controller/test_process'
      
      def expire_fragment(key, options=nil)
        if defined?(BASE_HOST)
          if @controller.nil?
            @controller = ActionController::Base.new
            @controller.request = ActionController::TestRequest.new
            @controller.request.host = BASE_HOST
            @controller.instance_eval do
              @url = ActionController::UrlRewriter.new(request, {})
            end
          end
  
          @controller.expire_fragment(key, options)
        end
      end
      
      def expire_service_index_tag_cloud
        expire_fragment(:controller => 'services', :action => 'index', :part => 'tag_cloud')
      end
      
      def expire_annotations_tags_flat_partial(annotatable_type, annotatable_id)
        expire_fragment(:controller => 'annotations', :action => 'tags_flat', :annotatable_type => annotatable_type, :annotatable_id => annotatable_id)
      end
      
      def reload_number_of_services_for_category_and_parents_caches(category)
        return if category.nil?
        
        # Call the method, but with recalculate = true, to repopulate the cache
        Categorising.number_of_services_for_category(category, true)
        
        # Parents
        c = category
        while c.has_parent?
          c = c.parent
          Categorising.number_of_services_for_category(c, true)
        end
      end
      
    end
    
  end
end