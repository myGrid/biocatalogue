# BioCatalogue: lib/bio_catalogue/twittering.rb
#
# Copyright (c) 2009, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

module BioCatalogue
  module Twittering
    
    TIMEOUT = 4
    
    def self.set_base_host(base_host)
      silence_warnings { BioCatalogue::Twittering.const_set "BASE_HOST", base_host } unless defined? BioCatalogue::Twittering.BASE_HOST
    end
    
    def self.post_tweet(tweet_text)
      return false if tweet_text.nil?
      return false unless ENABLE_TWITTER
      
      begin
        SystemTimer::timeout(TIMEOUT) {
          @httpauth ||= Twitter::HTTPAuth.new(TWITTER_ACCOUNT_EMAIL, TWITTER_ACCOUNT_PASSWORD, :ssl => true)
          @client ||= Twitter::Base.new(@httpauth)
          @client.update(tweet_text) 
        }
      rescue TimeoutError => ex
        Rails.logger.error("Tweeting timed out! Exception: #{ex.message}")
        Rails.logger.error(ex.backtrace.join("\n"))
        return true
      rescue Exception => ex
        Rails.logger.error("Failed to tweet! Exception: #{ex.class.name} - #{ex.message}")
        Rails.logger.error(ex.backtrace.join("\n"))
        return false
      end
    end
    
  end
end