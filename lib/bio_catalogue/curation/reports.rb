# BioCatalogue: lib/bio_catalogue/curation/reports.rb
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# A helper module for handling the data required for generating curation reports.

module BioCatalogue
  module Curation
    module Reports
    
      # Returns an Array of Arrays where the inner Arrays represent the 
      # clustered SoapOperation objects that may be similar.
      #
      # Note: the root Array is ordered by the most recently created SoapOperations. 
      def self.potential_duplicate_operations_within_service
        results = [ ]
        
        sql = "SELECT soap_service_id, name, COUNT(*) As count 
               FROM `soap_operations` 
               GROUP BY soap_service_id, name 
               HAVING ( COUNT(*) > 1 )"
        
        duplicates = ActiveRecord::Base.connection.select_all(sql)
        
        duplicates.each do |d|
          r = SoapOperation.find(:all, :conditions => { :soap_service_id => d['soap_service_id'], :name => d['name'] }, :include => :soap_service)
          
          results << r unless r.empty?
        end
        
        # Sort
        results.sort! do |x,y|
          latest_datetime_x = x.sort { |a,b| b.updated_at <=> a.updated_at }.first.updated_at
          latest_datetime_y = y.sort { |a,b| b.updated_at <=> a.updated_at }.first.updated_at
          
          latest_datetime_y <=> latest_datetime_x
        end
        
        return results
      end
    
    end
  end
end