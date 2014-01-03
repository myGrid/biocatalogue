namespace :biocatalogue do
  desc 'Generate a new CSV export'
  task :generate_csv_export => :environment do
    include CurationHelper
    puts "\nGenerating new CSV export for #{SITE_NAME} in #{Rails.env} mode.\n"
    spreadsheet_export
    puts "\nNew CSV export generated\n"
    puts "Created at: #{time_of_export(latest_csv_export)}.\n"
    puts "Zip saved as: #{latest_csv_export}."
  end
end