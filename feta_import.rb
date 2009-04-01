#!/usr/bin/env ruby

# This script imports most of the data from Feta into BioCatalogue.
#
# The Feta data should be obtained from: http://www.mygrid.org.uk/feta/mygrid/ and stored somewhere locally ('source directory').
# The directory structure under the URL above should be maintained in the source directory which you can specify when running the script.
#
#
# Usage: feta_import [options]
#    -s, --source=source              The source directory for the Feta files that need to be imported.
#                                     Default: {app_root}/feta
#    -e, --environment=name           Specifies the environment to run this import script under (test|development|production).
#                                     Default: development
#
#    -h, --help                       Show this help message.
#
#    -t, --test                       Run the script in test mode (so won't actually store anything in the db).
#
# 
# Examples of running this script:
#
#  ruby feta_import.rb -s "/home/Feta/"      <- runs the script on the development database, using the source files from "/home/Feta/".
#
#  ruby feta_import.rb -e production         <- runs the script on the production database, using the source files from the default location of "{app_root}/feta".
#
#  ruby feta_import.rb -e production -s "/home/Feta"      <- runs the script on the production database, using the source files from "/home/Feta/".
#
#  ruby feta_import.rb -s "/home/Feta/"      <- runs the script on the development database, using the source files from "/home/Feta/", and in test mode (so no data is written to the db).
#
#  ruby feta_import.rb -h                    <- displays help text for this script.  
#
#
# NOTE (1): $stdout and $stderr have been redirected to 'feta_import.log' so you won't see anything output in the console.
#
# 
# Depedencies:
# - Rails (v2.2.2)
# - libxml-ruby (> v1.1.2) [For windows users: make sure you install the windows specific ruby gem for this]
#                          [For linux users: this depends on the libxml2 C library]

require 'rubygems'
require 'optparse'
require 'libxml'
require 'benchmark'
require 'addressable/uri'

class FetaImporter
  include LibXML
  
  attr_accessor :options
  
  def initialize(args)
    @options = {
      :source      => "feta",
      :environment => (ENV['RAILS_ENV'] || "development").dup,
    }
    
    args.options do |opts|
      opts.on("-s", "--source=source", String, "The source directory for the Feta files that need to be imported.", "Default: {app_root}/feta") { |v| @options[:source] = v }
      opts.on("-e", "--environment=name", String,
              "Specifies the environment to run this import script under (test|development|production).",
              "Default: development") { |v| @options[:environment] = v }
    
      opts.separator ""
    
      opts.on("-h", "--help", "Show this help message.") { puts opts; exit }
      
      opts.on("-t", "--test", "Run the script in test mode (so won't actually store anything in the db).") { @options[:test] = true }
    
      opts.parse!
    end
    
    # Start the Rails app
      
    ENV["RAILS_ENV"] = @options[:environment]
    RAILS_ENV.replace(@options[:environment]) if defined?(RAILS_ENV)
    
    require File.dirname(__FILE__) + '/config/environment'
  end
  
  def run
    puts "=> Booting Feta to BioCatalogue import process. Running on #{@options[:environment]} database." 
    puts "=> Feta files will be loaded from: #{@options[:source]}"
    
    if @options[:test]
      puts ""
      puts "NOTE: you have asked me to run in test mode, so I won't write any data to the db."
    end
    
    source_path = @options[:source]

    preconditions_met = true
    
    # Check necessary folder(s) exist first
    
    unless File.exist?(source_path)
      puts ""
      puts "FATAL: source folder does not exist or cannot be accessed."
      preconditions_met = false
    end
    
    unless File.exist?(File.join(source_path, 'descriptions'))
      puts ""
      puts "FATAL: 'descriptions' folder missing."
      preconditions_met = false
    end
    
    if preconditions_met
      # Extra config options
      excluded_directories = [ "biomoby", "local_java_widget" ]
      
      # Variables for statistics
      stats = { } 
      stats["total_provider_folders_processed"] = 0
      stats["total_xml_files_found"] = 0
      stats["total_xml_files_successfully_processed"] = 0
      stats["total_xml_service_descriptions_found"] = 0
      stats["total_services_created"] = 0
      stats["total_services_existed_and_updated"] = 0
      stats["total_annotations_new"] = 0
      stats["total_annotations_already_exist"] = 0
      stats["ids_of_created_services"] = [ ]
      stats["ids_of_updated_services"] = [ ]
      
      # Get the Agent model object we will be using as the annotation source
      feta_importer_agent = Agent.find_by_name("feta_importer")
      
      # Exit if feta importer Agent is not available
      if feta_importer_agent.nil?
        puts ""
        puts "FATAL: the feta importer Agent has not been registered into the database yet. It is required to create annotations with the correct source. You may need to run rake db:migrate in order to update your db with the appropriate Agent record. Exiting... "
        return 1
      end
      
      # Run everything in a transaction
      
      begin
        Agent.transaction do
          # Go through all XML files and store metadata
          
          # 1st level is just folders
          Dir.chdir(File.join(source_path, "descriptions")) do
            Dir["*"].each do |folder_path|
              folder_path_end = File.basename(folder_path)
              if FileTest.directory?(folder_path)
                if excluded_directories.include?(folder_path_end.downcase)
                  puts ""
                  puts "> Folder '#{folder_path}' is excluded. Skipping and moving onto next..."
                else
                  puts ""
                  puts "> Folder '#{folder_path}' found. Processing..."
                  
                  Dir[File.join(folder_path, "*")].each do |path|
                    # 2nd level...
                    # Further folders are individual services, XML files are the metadata files.
                    if FileTest.directory?(path)
                      puts ""
                      puts "> Folder '#{path}' found. Processing..."
                      Dir[File.join(path, "*")].each do |path2|
                        if FileTest.directory?(path2)
                          puts ""
                          puts "WARNING: 3rd level folder found. Ignoring for now, but please check if it contains anything important."
                        elsif FileTest.file?(path2)
                          process_xml(path2, feta_importer_agent, stats)
                        end
                      end
                    elsif FileTest.file?(path)
                      process_xml(path, feta_importer_agent, stats)
                    end
                  end
                  
                  stats["total_provider_folders_processed"] = stats["total_provider_folders_processed"] + 1
                end
              end
            end
          end
          
          if @options[:test]
            raise "You asked me to test, so I am rolling back your transaction so nothing is stored in the db..."
          end
        end
      rescue Exception => ex
        puts ""
        puts "ERROR: exception occured and transaction has been rolled back. Exception:"
        puts ex.message
        puts ex.backtrace.join("\n")
      end 
      
      print_stats(stats)
    else
      puts ""
      puts "FATAL: Not all preconditions met. Exiting..."
      return 1
    end
  end
  
  protected
  
  def print_stats(stats)
    stats["ids_of_created_services"].sort!
    stats["ids_of_updated_services"].sort!
    
    stats["total_services_created"] = stats["ids_of_created_services"].length
    stats["total_services_existed_and_updated"] = stats["ids_of_updated_services"].length
    
    puts ""
    puts "Stats:"
    puts "------"
    
    stats.sort.each do |h|
      if h[1].is_a? Array
        puts "#{h[0].humanize} = #{h[1].to_sentence}"
      else
        puts "#{h[0].humanize} = #{h[1]}"  
      end
    end
  end
  
  def process_xml(path, agent, stats)
    if File.extname(path).downcase == ".xml"
      stats["total_xml_files_found"] = stats["total_xml_files_found"] + 1
      
      puts ""
      puts "> File '#{path}' found. Processing..."
      
      begin
        success = true
        
        # Load up XML doc and process the <serviceDescription> node...
        doc = XML::Parser.file(path).parse
        doc.root.namespaces.default_prefix = 'pd'

        doc.root.find('//pd:serviceDescription').each do |service_description_node|
          stats["total_xml_service_descriptions_found"] = stats["total_xml_service_descriptions_found"] + 1
          
          # Get WSDL URL
          wsdl_url = nil
          endpoint_url = nil
          
          wsdl_url_node = service_description_node.find_first("pd:interfaceWSDL")
          endpoint_url_node = service_description_node.find_first("pd:locationURL")
          
          if wsdl_url_node.nil? || (wsdl_url = wsdl_url_node.inner_xml).blank?
            success = false
            puts "ERROR: could not process file '#{path}' as it doesn't contain an <interfaceWSDL> element"
          elsif endpoint_url_node.nil? || (endpoint_url = endpoint_url_node.inner_xml).blank?
            success = false
            puts "ERROR: could not process file '#{path}' as it doesn't contain a <locationURL> element"
          else
            # Normalize WSDL URL
            wsdl_url = Addressable::URI.parse(wsdl_url).normalize.to_s
            
            soap_service = nil
            
            # Check if the service exists in the database
            if (existing_service = SoapService.check_duplicate(wsdl_url, endpoint_url)).nil?
              # Doesn't exist, so new SoapService needs to be created...
              
      
              soap_service = SoapService.new(:wsdl_location => wsdl_url)
              #success, data = soap_service.populate
              
              #unless stats["ids_of_created_services"].include?(soap_service.service.id)
              #stats["ids_of_created_services"] << soap_service.service.id
              #end
            else
              # Exists, so get the relevant SoapService object...
              
              unless stats["ids_of_created_services"].include?(existing_service.id) or stats["ids_of_updated_services"].include?(existing_service.id) 
                stats["ids_of_updated_services"] << existing_service.id 
              end
              
              existing_service.service_versions.each do |s_v|
                if s_v.service_versionified_type && (s_v_i = s_v.service_versionified).wsdl_location == wsdl_url
                  soap_service = s_v_i
                end
              end
            end
          end
        end
        
        stats["total_xml_files_successfully_processed"] = stats["total_xml_files_successfully_processed"] + 1 if success
      rescue Exception => ex
        puts "ERROR: exception occured whilst processing '#{path}':"
        puts ex.message
        puts ex.backtrace.join("\n")
      end
    end
  end
end

# Redirect $stdout and $stderr to log file
puts "Redirecting output of $stdout and $stderr to log file: feta_import.log ..."
$stdout = File.new("feta_import.log", "w")
$stdout.sync = true
$stderr = $stderr.reopen("feta_import.log", "w")
$stderr.sync = true

# Redirect warnings from libxml-ruby
LibXML::XML::Error.set_handler do |error|
  puts error.to_s
end

puts Benchmark.measure { FetaImporter.new(ARGV.clone).run }

# Reset $stdout and $stderr
$stdout = STDOUT
$stderr = STDERR
