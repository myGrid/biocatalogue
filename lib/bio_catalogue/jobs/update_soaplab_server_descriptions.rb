# BioCatalogue: lib/bio_catalogue/jobs/update_soaplab_server_descriptions.rb
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

module BioCatalogue
  module Jobs
    class UpdateSoaplabServerDescriptions < Struct.new(:server_id)
      def perform
        server = SoaplabServer.find_by_id(server_id)
          server.update_descriptions_from_soaplab! unless server.nil?
      end
    end    
  end
end