# BioCatalogue: lib/bio_catalogue/twittering.rb
#
# Copyright (c) 2009, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

require 'twitter'

module BioCatalogue
  module Twittering
    
    TIMEOUT = 4
    
    def self.set_base_host(base_host)
      silence_warnings { BioCatalogue::Twittering.const_set "BASE_HOST", base_host } unless defined? BioCatalogue::Twittering.BASE_HOST
    end
    
    def self.post_update(update_text)
      return false if update_text.nil?
      return false unless ENABLE_TWITTER
      
      begin
        SystemTimer::timeout(TIMEOUT) {
          @httpauth ||= Twitter::HTTPAuth.new(TWITTER_ACCOUNT_EMAIL, TWITTER_ACCOUNT_PASSWORD, :ssl => true)
          @client ||= Twitter::Base.new(@httpauth)
          @client.update(update_text) 
        }
      rescue TimeoutError
        Rails.logger.error("Tweeting timed out! Exception: #{ex.message}")
        Rails.logger.error(ex.backtrace)
        return true
      rescue Exception => ex
        Rails.logger.error("Failed to tweet! Exception: #{ex.class.name} - #{ex.message}")
        Rails.logger.error(ex.backtrace)
        return false
      end
    end
    
    def self.post_service_created(service)
      return false if service.nil?
      return false unless ENABLE_TWITTER
      
      if SITE_BASE_HOST
        msg = "New #{service.service_types[0]} service: #{service.name} - #{File.join(SITE_BASE_HOST, 'services', service.id.to_s)}"
        BioCatalogue::Twittering.post_update(msg)
      else
        log_no_base_host
        return false
      end
    end
    
    protected
      
    def log_no_base_host
      msg = "Twitter update not possible since SITE_BASE_HOST has not been set yet. (SITE_BASE_HOST should be set in your biocat_local file)."
      Rails.logger.error(msg)
      puts(msg)
    end
  
  end
end