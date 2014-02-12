namespace :biocatalogue do
  desc 'Generate the data for links checker report'
  task :generate_links_check_report => :environment do
    puts "\nGenerating links checker report for #{SITE_NAME} in #{Rails.env} mode.\n"
    BioCatalogue::LinkChecker::LinksChecker.new.run
    puts "\nData generated and stored as yml in data/#{(Rails.env).downcase}_reports/links_checker_report.yml"
  end
end