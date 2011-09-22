# BioCatalogue: app/helpers/soaplab_servers_helper.rb
#
# Copyright (c) 2008-2011, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details.

module SoaplabServersHelper
  def all_alternative_name_annotations_for_soaplab_server(server)
    annotations  = [ ]
    annotations.concat(server.annotations_with_attribute('alternative_name', true))
    return annotations
  end
  
  def number_of_services_from_soaplab_server(server)
    server.services.count
  end
end
