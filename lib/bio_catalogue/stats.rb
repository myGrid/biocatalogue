# BioCatalogue: lib/bio_catalogue/stats.rb
#
# Copyright (c) 2009, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# A helper class to generate system stats.

module BioCatalogue
  module Stats
    
    MODELS = [ Service, ServiceVersion, ServiceDeployment, SoapService, SoapOperation, SoapInput, SoapOutput,
               RestService, SoaplabServer, User, ServiceProvider, Annotation, ActivityLog ].freeze
    
    @@cache_key = "stats"
  
    def self.get_last_stats
      stats = nil
      
      cached_stats = Rails.cache.read(@@cache_key)
      
      if cached_stats.nil?
        # No stats in cache so send in a request to generate tasks as a background job
        submit_job_to_refresh_stats
      else
        stats = cached_stats
      end
      
      return stats
    end
    
    def self.generate_current_stats
      stats = StatsData.new
        
      # Write it to the cache...
      Rails.cache.write(@@cache_key, stats)
      
      return stats
    end
    
    def self.submit_job_to_refresh_stats
      # Only submit a job if if necessary... 
      unless BioCatalogue::DelayedJobs.job_exists?("BioCatalogue::Jobs::UpdateStats")
        Delayed::Job.enqueue(BioCatalogue::Jobs::UpdateStats.new)
      end
    end
    
    class StatsData
      attr_reader :created_at
      
      def initialize
        @created_at = Time.now
        load_data
      end
      
      def load_data
        load_model_totals
        load_metadata_counts_per_service
        load_metadata_counts_grouped_by_counts
        load_searches_all
        load_searches_grouped_by_frequency
      end
      
      # Returns: Integer
      def total_for_model(model, span=:all)
        @model_totals[model][span]    
      end
      
      def metadata_counts_per_service
        @metadata_counts_per_service
      end
      
      # The 'type' should be one of the types available in the results hash of 
      # BioCatalogue::Annotations.metadata_counts_for_service
      #
      # Returns: Integer
      def total_metadata_on_services(type=:all)
        @metadata_counts_per_service.values.map{|v| v[type]}.sum
      end
  
      # The 'type' should be one of the types available in the results hash of 
      # BioCatalogue::Annotations.metadata_counts_for_service
      #
      # Returns: Float
      def avg_metadata_per_service(type=:all)
        @metadata_counts_per_service.values.map{|v| v[type]}.mean.round
      end
      
      # The 'type' should be one of the types available in the results hash of 
      # BioCatalogue::Annotations.metadata_counts_for_service
      #
      # Returns: Hash - { :count => max_metadata_count, :services => [ list of Services that have this count ] }
      def max_metadata_on_services(type=:all)
        result = { }
        max = @metadata_counts_per_service.values.map{|v| v[type]}.max
        result[:count] = max
        result[:services] = @metadata_counts_grouped_by_counts[type][max].map{|s_id| Service.find_by_id(s_id)}.reject{|s| s.blank?}
        result
      end
      
      # The 'type' should be one of the types available in the results hash of 
      # BioCatalogue::Annotations.metadata_counts_for_service
      #
      # Returns: Hash - { :count => min_metadata_count, :services => [ list of Services that have this count ] }
      def min_metadata_on_services(type=:all)
        result = { }
        min = @metadata_counts_per_service.values.map{|v| v[type]}.min
        result[:count] = min
        result[:services] = @metadata_counts_grouped_by_counts[type][min].map{|s_id| Service.find_by_id(s_id)}.reject{|s| s.blank?}
        result
      end
      
      # Returns: Integer
      def total_searches_non_unique
        @searches_all.length
      end
      
      # Returns: Integer
      def total_searches_unique
        @searches_grouped_by_frequency.keys.length
      end
      
      # Returns an Array of Arrays:
      # [ [ "query1", frequency ], [ "query2", frequency ], ... ]
      def search_queries_with_frequencies_sorted_descending
        @searches_grouped_by_frequency.to_a.sort{|a,b| b[1] <=> a[1]}
      end
      
      protected
      
      def load_model_totals
        @model_totals = { }
        MODELS.each do |m|
          @model_totals[m] = { }
          @model_totals[m][:all] = m.count
          @model_totals[m][:last_7] = m.count(:conditions => [ "created_at >= ?", Time.now.ago(7.days)])
          @model_totals[m][:last_30] = m.count(:conditions => [ "created_at >= ?", Time.now.ago(30.days)])
          @model_totals[m][:last_90] = m.count(:conditions => [ "created_at >= ?", Time.now.ago(90.days)])
          @model_totals[m][:last_180] = m.count(:conditions => [ "created_at >= ?", Time.now.ago(180.days)])
        end
      end
      
      # Maintains a hash for all service metadat counts where:
      # { service_id => metadata_counts_hash (as per return value of BioCatalogue::Annotations.metadata_counts_for_service) }
      def load_metadata_counts_per_service
        @metadata_counts_per_service = Hash[* Service.all.map{|s| [ s.id, BioCatalogue::Annotations.metadata_counts_for_service(s) ] }.flatten]
      end
      
      # Maintains a hash of metadata counts that are grouped by type and then counts.
      # ie: { type1 => { count_value1 => [ service ids with that count ], count_value2 => [ service ids with that count ], ... }, type2 => ..., ... }
      # where type is one of the types available in the results hash of BioCatalogue::Annotations.metadata_counts_for_service
      def load_metadata_counts_grouped_by_counts
        @metadata_counts_grouped_by_counts = { }
        
        @metadata_counts_per_service.values[0].keys.each do |type|
          @metadata_counts_grouped_by_counts[type] = { } if @metadata_counts_grouped_by_counts[type].nil?
          
          counts = @metadata_counts_per_service.values.map{|v| v[type]}.uniq
          
          counts.each do |c|
            @metadata_counts_grouped_by_counts[type][c] = @metadata_counts_per_service.select{|k,v| v[type] == c}.map{|el| el[0]}
          end
        end
        
        @metadata_counts_grouped_by_counts
      end
      
      # Maintains a non unique list of all the searches carried out.
      def load_searches_all
        @searches_all = ActivityLog.find_all_by_action('search').map{|s| s.data[:query]}.reject{|s| s.blank?}
      end
      
      # Maintains a hash of all the searches carried out and the frequency of each. 
      # ie: { "query1" => frequency, "query2" => frequency, ... }   
      def load_searches_grouped_by_frequency
        @searches_grouped_by_frequency = { }
        
        @searches_all.each do |s|
          @searches_grouped_by_frequency[s].nil? ? @searches_grouped_by_frequency[s] = 1 : @searches_grouped_by_frequency[s] = @searches_grouped_by_frequency[s] + 1
        end
        
        @searches_grouped_by_frequency
      end
      
    end
  
  end
end