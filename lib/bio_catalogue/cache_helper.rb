# BioCatalogue: lib/bio_catalogue/cache_helper.rb
#
# Copyright (c) 2009, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# Helper module to provide functions to aid in caching.

module BioCatalogue
  module CacheHelper
    
    NONE_VALUE = "<none>".freeze
    
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
            
            memcache_options = {
              :namespace   => config['namespace'],
              :readonly    => false,
              :multithread => true,
              :failover    => true,
              :timeout     => 0.5,
              :logger      => Rails.logger,
              :no_reply    => false,
            }
            
            memcache_client = MemCache.new(memcache_servers, memcache_options)
            
            Util.say("memcache servers: #{memcache_client.servers.inspect}") 
            
            # Set the global CACHE variable...
            # BUT this MUST NOT be used directly, use Rails.cache instead.
            silence_warnings { Object.const_set "CACHE", memcache_client }
            
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
      CACHE.reset if defined?(CACHE)
    end
    
    def self.cache_key_for(type, *args)
      case type
        when :metadata_counts_for_service
          "metadata_counts_for_service_#{args[0].id}"
      end
    end
    
    module Expires
      
      def expire_service_index_tag_cloud
        expire_fragment(:controller => 'services', :action => 'index', :action_suffix => 'tag_cloud')
      end
      
    end
    
  end
end