# BioCatalogue: app/lib/stats.rb
#
# Copyright (c) 2008, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# A helper class to generate system stats.

module BioCatalogue
  class Stats
    def initialize
      
    end
    
    # Returns: Integer
    def total(model)
      model.count
    end
    
    # The 'type' should be one of the types available in the results hash of 
    # BioCatalogue::Annotations.metadata_counts_for_service
    #
    # Returns: Integer
    def total_metadata_on_services(type=:total)
      self.metadata_counts_per_service.values.map{|v| v[type]}.sum
    end

    # The 'type' should be one of the types available in the results hash of 
    # BioCatalogue::Annotations.metadata_counts_for_service
    #
    # Returns: Float
    def avg_metadata_per_service(type=:total)
      self.metadata_counts_per_service.values.map{|v| v[type]}.mean.round
    end
    
    # The 'type' should be one of the types available in the results hash of 
    # BioCatalogue::Annotations.metadata_counts_for_service
    #
    # Returns: Hash - { :count => max_metadata_count, :services => [ list of Services that have this count ] }
    def max_metadata_on_services(type=:total)
      result = { }
      max = self.metadata_counts_per_service.values.map{|v| v[type]}.max
      result[:count] = max
      result[:services] = self.metadata_counts_grouped_by_counts[type][max].map{|s_id| Service.find(s_id)}
      result
    end
    
    # The 'type' should be one of the types available in the results hash of 
    # BioCatalogue::Annotations.metadata_counts_for_service
    #
    # Returns: Hash - { :count => min_metadata_count, :services => [ list of Services that have this count ] }
    def min_metadata_on_services(type=:total)
      result = { }
      min = self.metadata_counts_per_service.values.map{|v| v[type]}.min
      result[:count] = min
      result[:services] = self.metadata_counts_grouped_by_counts[type][min].map{|s_id| Service.find(s_id)}
      result
    end
    
    protected
    
    # Maintains a hash for all service metadat counts where:
    # { service_id => metadata_counts_hash (as per return value of BioCatalogue::Annotations.metadata_counts_for_service) }
    def metadata_counts_per_service
      @metadata_counts_per_service ||= Hash[* Service.all.map{|s| [ s.id, BioCatalogue::Annotations.metadata_counts_for_service(s) ] }.flatten]
    end
    
    # Maintains a hash of metadata counts that are grouped by type and then counts.
    # ie: { type1 => { count_value1 => [ service ids with that count ], count_value2 => [ service ids with that count ], ... }, type2 => ..., ... }
    # where type is one of the types available in the results hash of BioCatalogue::Annotations.metadata_counts_for_service
    def metadata_counts_grouped_by_counts
      if @metadata_counts_grouped_by_counts.nil?
        @metadata_counts_grouped_by_counts = { }
        
        self.metadata_counts_per_service.values[0].keys.each do |type|
          @metadata_counts_grouped_by_counts[type] = { } if @metadata_counts_grouped_by_counts[type].nil?
          
          counts = self.metadata_counts_per_service.values.map{|v| v[type]}.uniq
          
          counts.each do |c|
            @metadata_counts_grouped_by_counts[type][c] = self.metadata_counts_per_service.select{|k,v| v[type] == c}.map{|el| el[0]}
          end
        end
        
      end
      @metadata_counts_grouped_by_counts
    end
    
  end
end