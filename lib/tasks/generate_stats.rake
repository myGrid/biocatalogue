namespace :biocatalogue do
  desc 'Generate service, users, etc. statisticss for the catalogue. Does not use delayed job.'
  task :generate_stats => :environment do
    puts "\nGenerating new statistics for #{SITE_NAME} ...\n"
    stats = BioCatalogue::Stats.generate_current_stats
    Rails.cache.write('stats', stats)
    puts "\nNew statistics generated at #{stats.created_at}.\n"
  end
end