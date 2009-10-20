# BioCatalogue: lib/bio_catalogue/delayed_jobs.rb
#
# Copyright (c) 2009, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

module BioCatalogue
  module DelayedJobs
    
    def self.job_exists?(job_name)
      Delayed::Job.find(:all, :conditions => [ "delayed_jobs.handler LIKE ?", "%#{job_name}%" ]).length > 0
    end
    
  end
end