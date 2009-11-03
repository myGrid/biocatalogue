# BioCatalogue: lib/tasks/clean_db_for_dev.rake
#
# Copyright (c) 2009, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

namespace :biocatalogue do
  desc "Remove expired sessions from the database. Default expiry age for sessions is 3 days, but can be specified using AGE=x"
  task :remove_expired_sessions => :environment do
    
    #Default age to 3 days
    day_threshold = ENV["AGE"] ? ENV["AGE"].to_i : 3
    
    sql = "DELETE FROM sessions WHERE (updated_at < '#{Time.now.advance(:days => -day_threshold).to_s(:db)}')"
    
    rows_deleted = ActiveRecord::Base.connection.delete(sql)
    
    #Log/output number of sessions removed
    BioCatalogue::Util.say "#{rows_deleted} expired sessions removed."
  end
end
