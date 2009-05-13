# BioCatalogue: lib/bio_catalogue/stats.rb
#
# Copyright (c) 2009, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# A helper class to generate system stats.

module BioCatalogue
  class Stats
    # Returns: Integer
    def total_for_model(model)
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
    
    # Returns: Integer
    def total_searches_non_unique
      self.searches_all.length
    end
    
    # Returns: Integer
    def total_searches_unique
      self.searches_grouped_by_frequency.keys.length
    end
    
    # Returns an Array of Arrays:
    # [ [ "query1", frequency ], [ "query2", frequency ], ... ]
    def search_queries_with_frequencies_sorted_descending
      self.searches_grouped_by_frequency.to_a.sort{|a,b| b[1] <=> a[1]}
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
    
    # Maintains a non unique list of all the searches carried out.
    def searches_all
      @searches_all ||= ActivityLog.find_all_by_action('search').map{|s| s.data[:query]}
    end
    
    # Maintains a hash of all the searches carried out and the frequency of each. 
    # ie: { "query1" => frequency, "query2" => frequency, ... }   
    def searches_grouped_by_frequency
      if @searches_grouped_by_frequency.nil?
        @searches_grouped_by_frequency = { }
        
        @searches_all.each do |s|
          @searches_grouped_by_frequency[s].nil? ? @searches_grouped_by_frequency[s] = 1 : @searches_grouped_by_frequency[s] = @searches_grouped_by_frequency[s] + 1
        end
      end
      
      @searches_grouped_by_frequency
    end
    
  end
end