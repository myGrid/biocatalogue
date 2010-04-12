# BioCatalogue: lib/bio_catalogue/jobs/post_tweet
#
# Copyright (c) 2009, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

module BioCatalogue
  module Jobs
    class PostTweet < Struct.new(:message)
      def perform
        BioCatalogue::Util.say "I AM TWEETING! Message: #{message}"
        BioCatalogue::Twittering.post_tweet(message)
      end    
    end
  end
end