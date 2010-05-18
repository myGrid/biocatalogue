# BioCatalogue: lib/bio_catalogue/delayed_jobs.rb
#
# Copyright (c) 2009, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

module BioCatalogue
  module DelayedJobs
    
    def self.job_exists?(job_name, additional_strings_to_find=[])
      conditions = [ ]
      conditions << "delayed_jobs.handler LIKE ?"
      conditions << "%#{job_name}%"
      
      additional_strings_to_find.each do |s|
        conditions[0] = conditions[0] + " AND delayed_jobs.handler LIKE ?"
        conditions << "%#{s}%"
      end
      
      Delayed::Job.find(:all, :conditions => conditions).length > 0
    end
    
  end
end