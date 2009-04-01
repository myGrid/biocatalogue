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
#  ruby feta_import.rb -s "/home/jits/Feta/"                <- runs the script on the development database, using the source files from "/home/jits/Feta/" (absolute path).
#
#  ruby feta_import.rb -s "./../../Feta/"                   <- runs the script on the development database, using the source files from "./../../Feta/" (relative path; which would look for the 'Feta' folder in the folder 2 levels above the current folder). 
#
#  ruby feta_import.rb -e production                        <- runs the script on the production database, using the source files from the default location of "{app_root}/feta".
#
#  ruby feta_import.rb -e production -s "/home/jits/Feta/"  <- runs the script on the production database, using the source files from "/home/jits/Feta/".
#
#  ruby feta_import.rb -s "/home/jits/Feta/" -t             <- runs the script on the development database, using the source files from "/home/jits/Feta/", and in test mode (so no data is written to the db).
#
#  ruby feta_import.rb -h                                   <- displays help text for this script.  
#
#
# NOTE (1): $stdout has been redirected to 'feta_import.log' so you won't see any normal output in the console.
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

class Counter
  attr_accessor :count
  
  def initialize
    @count = 0
  end
  
  def increment(amount=nil)
    if amount.nil?
      @count = @count + 1
    else
      @count = @count + amount
    end
  end
  
  def decrement(amount=nil)
    if amount.nil?
      @count = @count - 1
    else
      @count = @count - amount
    end
  end
end

class FetaImporter
  include LibXML
  
  attr_accessor :options, :agent
  
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
    
    # Get the Agent model object we will be using as the annotation source
    @agent = Agent.find_by_name("feta_importer")
    
    # Exit if feta importer Agent is not available
    if @agent.nil?
      raise "FATAL: the feta importer Agent has not been registered into the database yet. It is required to create annotations with the correct source. You may need to run rake db:migrate in order to update your db with the appropriate Agent record. Exiting... "
    end
  end
  
  def run
    puts "=> Booting Feta to BioCatalogue import process. Running on #{@options[:environment]} database." 
    puts "=> Feta files will be loaded from: #{@options[:source]}"
    
    if @options[:test]
      puts ""
      puts "*********************************************************************************"
      puts "NOTE: you have asked me to run in test mode, so I won't write any data to the db."
      puts "*********************************************************************************"
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
      excluded_directories = [ "biomoby", "local_java_widget", "govizservice" ]
      
      # Variables for statistics
      stats = { } 
      stats["total_provider_folders_processed"] = Counter.new
      stats["total_xml_files_found"] = Counter.new
      stats["total_xml_files_successfully_processed"] = Counter.new
      stats["total_xml_service_descriptions_found"] = Counter.new
      stats["total_xml_service_descriptions_are_for_existing_services"] = Counter.new
      stats["total_xml_service_descriptions_are_for_new_services"] = Counter.new
      stats["total_services_created"] = Counter.new
      stats["total_services_existed_and_updated"] = Counter.new
      stats["total_annotations_new"] = Counter.new
      stats["total_annotations_already_exist"] = Counter.new
      stats["total_annotations_failed"] = Counter.new
      stats["ids_of_created_services"] = [ ]
      stats["ids_of_updated_services"] = [ ]
      

      # Run everything in a transaction
      
      begin
        Agent.transaction do
          # Go through all XML files and store metadata
          
          descriptions_folder_path = File.join(source_path, "descriptions")
          
          puts ""
          puts "=> Processing all XML files within the '#{descriptions_folder_path}' folder..."
          puts ""
          
          Dir.chdir(descriptions_folder_path) do
            # 1st level is just provider folders
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
                    # Further folders are individual services folders, XML files are the metadata files for operations.
                    if FileTest.directory?(path)
                      puts ""
                      puts "> Folder '#{path}' found. Processing..."
                      Dir[File.join(path, "*")].each do |path2|
                        if FileTest.directory?(path2)
                          puts ""
                          puts "WARNING: 3rd level folder found. Ignoring for now, but please check if it contains anything important."
                        elsif FileTest.file?(path2)
                          process_xml(path2, stats, File.basename(path))
                        end
                      end
                    elsif FileTest.file?(path)
                      process_xml(path, stats)
                    end
                  end
                  
                  stats["total_provider_folders_processed"].increment
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
      elsif h[1].is_a? Counter
        puts "#{h[0].humanize} = #{h[1].count}" 
      else
        puts "#{h[0].humanize} = #{h[1]}"  
      end
    end
  end
  
  def process_xml(path, stats, second_level_folder_name=nil)
    if File.extname(path).downcase == ".xml"
      stats["total_xml_files_found"].increment
      
      puts ""
      puts ">> XML file '#{path}' found. Processing..."
      puts "INFO: 2nd level folder name = #{second_level_folder_name} (this will be stored as a name annotation [ie: a name alias])" unless second_level_folder_name.blank?
      
      begin
        success = true
        
        # Load up XML doc and process the <serviceDescription> node...
        doc = XML::Parser.file(path).parse
        doc.root.namespaces.default_prefix = 'pd'

        doc.root.find('//pd:serviceDescription').each do |service_description_node|
          stats["total_xml_service_descriptions_found"].increment
          
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
              
              stats["total_xml_service_descriptions_are_for_new_services"].increment
      
              soap_service = SoapService.new(:wsdl_location => wsdl_url)
              new_service_success, data = soap_service.populate
              
              if new_service_success
                new_service_success = soap_service.submit_service(data["endpoint"], @agent, { })
                
                if new_service_success
                  puts "INFO: new service (ID: #{soap_service.service(true).id}, WSDL URL: '#{wsdl_url}') successfully created!"
                  stats["ids_of_created_services"] << soap_service.service.id
                else
                  puts "ERROR: failed to carry out submit_service of SoapService object with WSDL URL '#{wsdl_url}' (ie: db has not been populated with the SoapService and associated objects). Check the relevant Rails log file for more info."
                  success = false
                end
              else
                puts "ERROR: failed to populate SoapService object from WSDL URL '#{wsdl_url}'. Error messages: #{soap_service.errors.full_messages.to_sentence}"
                success = false
              end
            else
              # Exists, so get the relevant SoapService object...
              
              stats["total_xml_service_descriptions_are_for_existing_services"].increment
              
              puts "INFO: existing matching service found (ID: #{existing_service.id}, WSDL URL: '#{wsdl_url}')."
              
              unless stats["ids_of_created_services"].include?(existing_service.id) or stats["ids_of_updated_services"].include?(existing_service.id) 
                stats["ids_of_updated_services"] << existing_service.id
              end
              
              existing_service.service_versions.each do |s_v|
                if (s_v.service_versionified_type == "SoapService") && ((s_v_i = s_v.service_versionified).wsdl_location.downcase == wsdl_url.downcase)
                  soap_service = s_v_i
                end
              end
            end
            
            # Add annotations from the metadata now...
            if success
              # If this XML file came from a second level folder, store it as a name alias for the service.
              # BUT only if it doesn't match the existing name of the service.
              unless second_level_folder_name.blank?
                if second_level_folder_name == soap_service.name
                  puts "INFO: 2nd level folder name is the same as the actual service name, so not creating an annotation for this."
                else
                  create_annotation(soap_service, "name", second_level_folder_name, stats)  
                end
              end
            end
          end
        end
        
        stats["total_xml_files_successfully_processed"].increment if success
      rescue Exception => ex
        puts "ERROR: exception occured whilst processing '#{path}':"
        puts ex.message
        puts ex.backtrace.join("\n")
      end
    else
      puts ""
      puts "INFO: non XML file encountered. Ignoring..."
    end
  end
  
  def create_annotation(annotatable, attribute, value, stats)
    annotatable_type = annotatable.class.name
    value = CGI.unescape(value)
    
    ann = Annotation.new(:attribute_name => attribute,
                         :value => value,
                         :source_type => "Agent",
                         :source_id => @agent.id,
                         :annotatable_type => annotatable_type,
                         :annotatable_id => annotatable.id)

    if ann.save
      stats["total_annotations_new"].increment
      puts "INFO: annotation successfully created. Annotatable: #{annotatable_type} ID #{annotatable.id}; Attribute: '#{attribute}'; Value: '#{value}';"
    else
      # Check if it failed because of duplicate...
      if ann.errors.full_messages.include?("This annotation already exists and is not allowed to be created again.")
        stats["total_annotations_already_exist"].increment
        puts "INFO: duplicate annotation detected so not storing it again. Annotatable: #{annotatable_type} ID #{annotatable.id}; Attribute: '#{attribute}'; Value: '#{value}';"
      else
        stats["total_annotations_failed"].increment
        puts "ERROR: creation of annotation failed! Annotatable: #{annotatable_type} ID #{annotatable.id}; Attribute: '#{attribute}'; Value: '#{value}';"
      end
    end
  end
end

# Redirect $stdout to log file
puts "Redirecting output of $stdout to log file: feta_import.log ..."
$stdout = File.new("feta_import.log", "w")
$stdout.sync = true

# Redirect warnings from libxml-ruby
LibXML::XML::Error.set_handler do |error|
  #puts error.to_s
end

puts Benchmark.measure { FetaImporter.new(ARGV.clone).run }

# Reset $stdout
$stdout = STDOUT
