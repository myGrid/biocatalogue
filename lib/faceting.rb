# BioCatalogue: app/lib/faceting.rb
#
# Copyright (c) 2009, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# Module to carry out the bulk of the logic for filtering, faceting,
# advanced search, and so on.

module BioCatalogue
  module Faceting
    
    # Gets all the service providers and their counts of services.
    # Example return data:
    # [ { "name" => "ebi.ac.uk", "count" => "12" }, { "name" => "example.com", "count" => "11" }, ... ]
    def self.get_facets_for_service_providers(limit=nil)
      # NOTE: this query has only been tested to work with MySQL 5.0.x
      sql = "SELECT service_providers.name AS name, COUNT(*) AS count 
            FROM service_providers 
            INNER JOIN service_deployments ON service_providers.id = service_deployments.service_provider_id 
            INNER JOIN services ON services.id = service_deployments.service_id 
            GROUP BY service_providers.id 
            ORDER BY COUNT(*) DESC"
      
      # If limit has been provided in the URL then add that to query.
      if !limit.nil? && limit.is_a?(Fixnum) && limit > 0
        sql += " LIMIT #{limit}"
      end
       
      return ActiveRecord::Base.connection.select_all(sql)
    end
    
    # Gets all the different service types and their counts of services.
    # Example return data:
    # [ { "name" => "SOAP", "count" => "102" }, { "name" => "REST", "count" => "11" }, ... ]
    def self.get_facets_for_service_types(limit=nil)
      facets = { }
      
      # NOTE: this query has only been tested to work with MySQL 5.0.x
      sql = "SELECT service_versions.service_versionified_type AS name, COUNT(*) AS count 
            FROM service_versions 
            INNER JOIN services ON services.id = service_versions.service_id 
            GROUP BY service_versions.service_versionified_type 
            ORDER BY COUNT(*) DESC"
      
      # If limit has been provided in the URL then add that to query.
      if !limit.nil? && limit.is_a?(Fixnum) && limit > 0
        sql += " LIMIT #{limit}"
      end
       
      facets = ActiveRecord::Base.connection.select_all(sql)
      
      # Need to "massage" the returned data...
      
      facets.each do |f|
        f["name"] = f["name"].constantize.new.service_type_name
      end
      
      return facets
    end
    
  end
end