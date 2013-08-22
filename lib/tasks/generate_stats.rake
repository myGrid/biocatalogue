

task :generate_stats => :environment do
  stats = BioCatalogue::Stats.generate_current_stats
  Rails.cache.write('stats', stats)
  puts "\nNew statstics generated at #{stats.created_at}\n "
end