# BioCatalogue: lib/bio_catalogue/service_updater.rb
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# This module holds logic for service updater related functionality.
# Service updating can involve things like WSDL sync, auto tagging and other such auto curation tasks.
# 
# NOTE: where possible, logic should go in the relevant Models 
#       (e.g.: WSDL sync is in the SoapService model). This module
#       is for generic and/or utility functionality related to service 
#       update functionality. 

module BioCatalogue
  module ServiceUpdater
    
    def self.submit_job_to_run_service_updater(service_id)
      # Only submit a job if if necessary... 
      unless BioCatalogue::DelayedJobs.job_exists?("BioCatalogue::Jobs::RunServiceUpdater", [ "service_id: #{service_id}" ])
        Delayed::Job.enqueue(BioCatalogue::Jobs::RunServiceUpdater.new(service_id))
      end
    end
    
  end
end