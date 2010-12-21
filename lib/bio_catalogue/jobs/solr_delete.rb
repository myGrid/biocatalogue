# BioCatalogue: lib/bio_catalogue/jobs/solr_delete.rb
#
# Copyright (c) 2009, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# Use this job to perform deletes from
# the index in a background process.
#
# The motivation for this is the timing out
# some db transactions, especially deletes and 
# believed to be caused by the coupling between
# database and solr deletes.

module BioCatalogue
  module Jobs
    class SolrDelete < Struct.new(:solr_ids)
      def perform
          begin
          	ActsAsSolr::Post.execute(Solr::Request::Delete.new(:id => solr_ids))
         	rescue Exception => ex
          	Rails.logger.error("problems deleting solr docs ") 
            Rails.logger.error(ex.to_s)
         	end
      end   
    end
  end
end