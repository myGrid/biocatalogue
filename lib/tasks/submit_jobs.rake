# BioCatalogue: lib/tasks/submit_jobs.rake
#
# Copyright (c) 2009, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

namespace :biocatalogue do
  namespace :submit do
    
    desc 'Submits a job to recalculate the total annotation counts (including grouped totals) and cache them (see biocat_main.rb for cache time)'
    task :calculate_annotation_counts => :environment do
      Delayed::Job.enqueue(BioCatalogue::Jobs::CalculateAnnotationCountsJob.new)
    end
    
  end
end