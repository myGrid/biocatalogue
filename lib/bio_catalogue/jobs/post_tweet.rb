# BioCatalogue: lib/bio_catalogue/jobs/post_tweet
#
# Copyright (c) 2009, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

module BioCatalogue
  module Jobs
    class PostTweet
      attr_accessor :action
      attr_accessor :data
      
      def initialize(action, *args)
        @action = action
        @data = args.extract_options!
      end
      
      def perform
        puts "I AM TWEETING! Action: #{@action}"
        
        case @action
          when :service_create
            service = Service.find_by_id(@data[:service_id])
            BioCatalogue::Twittering.post_service_created(service) unless service.nil?         
        end
      end
    end    
  end
end