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
# NOTE (2): this script assumes that any Soaplab services found are already in the BioCatalogue so we don't have to create all the Soaplab Server stuff.
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
      excluded_directories = [ "biomoby", "local_java_widget", "govizservice", "soaplab_manchester", "soaplab_ebi" ]
      
      # Variables for statistics
      stats = { } 
      stats["total_provider_folders_processed"] = Counter.new
      stats["total_xml_files_found"] = Counter.new
      stats["total_xml_files_successfully_processed"] = Counter.new
      stats["total_xml_service_descriptions_found"] = Counter.new
      stats["total_xml_service_descriptions_are_wsdl_services"] = Counter.new
      stats["total_xml_service_descriptions_are_for_existing_services"] = Counter.new
      stats["total_xml_service_descriptions_are_for_new_services"] = Counter.new
      stats["total_xml_service_operations_found"] = Counter.new
      stats["total_xml_service_operations_that_do_not_exist_in_service_now"] = Counter.new
      stats["total_xml_service_input_parameters_found"] = Counter.new
      stats["total_xml_service_output_parameters_found"] = Counter.new
      stats["total_xml_service_parameters_that_do_not_exist_in_service_now"] = Counter.new
      stats["total_services_new"] = Counter.new
      stats["total_services_existed_and_updated"] = Counter.new
      stats["total_annotations_new"] = Counter.new
      stats["total_annotations_already_exist"] = Counter.new
      stats["total_annotations_failed"] = Counter.new
      stats["ids_of_new_services"] = [ ]
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
    stats["ids_of_new_services"].sort!
    stats["ids_of_updated_services"].sort!
    
    stats["total_services_new"] = stats["ids_of_new_services"].length
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
      puts "INFO: 2nd level folder name = '#{second_level_folder_name}' (this will be stored as a name annotation [ie: a name alias])" unless second_level_folder_name.blank?
      
      begin
        success = true
        
        # Load up XML doc and process the <serviceDescription> node(s)...
        doc = XML::Parser.file(path).parse
        doc.root.namespaces.default_prefix = 'pd'

        doc.root.find('//pd:serviceDescription').each do |service_description_node|
          stats["total_xml_service_descriptions_found"].increment
          
          service_type = service_description_node.find_first("pd:serviceType").inner_xml
          
          # Only continue if WSDL service
          # Note: we are assuming that any Soaplab services found are already 
          # in the BioCatalogue so we don't have to create all the Soaplab Server stuff.
          if ["wsdl service", "soaplab service"].include?(service_type.downcase)
            stats["total_xml_service_descriptions_are_wsdl_services"].increment
            
            # Get WSDL and endpoint URLs
            wsdl_url = nil
            endpoint_url = nil
            
            # <interfaceWSDL>
            wsdl_url_node = service_description_node.find_first("pd:interfaceWSDL")
            
            # <locationURL>
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
                    stats["ids_of_new_services"] << soap_service.service.id
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
                
                unless stats["ids_of_new_services"].include?(existing_service.id) or stats["ids_of_updated_services"].include?(existing_service.id) 
                  stats["ids_of_updated_services"] << existing_service.id
                end
                
                existing_service.service_versions.each do |s_v|
                  if (s_v.service_versionified_type == "SoapService") && ((s_v_i = s_v.service_versionified).wsdl_location.downcase == wsdl_url.downcase)
                    soap_service = s_v_i
                  end
                end
              end
              
              # Add annotations from the metadata and operations now...
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
                
                # Process <serviceOperation> node(s)
                service_description_node.find('//pd:serviceOperation').each do |operation_node|
                  
                  stats["total_xml_service_operations_found"].increment
                  
                  # <operationName>
                  op_name = operation_node.find_first("pd:operationName").inner_xml
                  
                  # A special case for VBI services is that some operation names are eg: "getIprscan.aboutOperations".
                  # So need to split...
                  op_name_split = op_name.split('.')
                  if op_name_split.length > 1
                    op_name = op_name_split[1]
                  end
                  
                  # Find the operation in the service
                  operation = soap_service.soap_operations.find(:first, :conditions => { :name => op_name })
                  
                  if operation.nil?
                    stats["total_xml_service_operations_that_do_not_exist_in_service_now"].increment
                    puts "WARNING: could not get SoapOperation matching '#{op_name}' - most likely the service has changed. Skipping..."
                  else
                    
                    # <operationDescriptionText>
                    op_desc_text = operation_node.find_first("pd:operationDescriptionText").inner_xml
                    create_annotation(operation, "description", op_desc_text, stats) unless op_desc_text.blank?
                    
                    # <operationTask>
                    operation_task_node = operation_node.find_first("pd:operationTask")
                    unless operation_task_node.nil?
                      val = operation_task_node.inner_xml
                      create_annotation(operation, "<http://www.mygrid.org.uk/mygrid-moby-service#performsTask>", val, stats, true)
                      create_annotation(operation, "tag", val, stats, true)
                    end
  
                    # <operationMethod>
                    operation_method_node = operation_node.find_first("pd:operationMethod")
                    unless operation_method_node.nil?
                      val = operation_method_node.inner_xml
                      create_annotation(operation, "<http://www.mygrid.org.uk/mygrid-moby-service#usesMethod>", val, stats, true)
                      create_annotation(operation, "tag", val, stats, true)
                    end
                    
                    # <operationResource>
                    operation_resource_node = operation_node.find_first("pd:operationResource")
                    unless operation_resource_node.nil?
                      val = operation_resource_node.inner_xml
                      create_annotation(operation, "<http://www.mygrid.org.uk/mygrid-moby-service#usesResource>", val, stats, true)
                      create_annotation(operation, "tag", val, stats, true)
                    end
                    
                    # Process <parameter> node(s) in <operationInputs>
                    operation_node.find('//pd:operationInputs/pd:parameter').each do |parameter_node|
                      
                      stats["total_xml_service_input_parameters_found"].increment
                       
                      process_parameter_xml(parameter_node, operation.soap_inputs, stats)
                      
                    end
                    
                    # Process <parameter> node(s) in <operationOutputs>
                    operation_node.find('//pd:operationOutputs/pd:parameter').each do |parameter_node|
                      
                      stats["total_xml_service_output_parameters_found"].increment
                      
                      process_parameter_xml(parameter_node, operation.soap_outputs, stats)
                      
                    end
                    
                    # Finally, add the link to the example workflow
                    example_workflow_url = "http://www.mygrid.org.uk/feta/mygrid/example_workflow/#{path.gsub(".xml", "")}_workflow.xml"
                    create_annotation(operation, "example_workflow", example_workflow_url, stats)
                    
                  end
                  
                end
              end
            end
          else
            puts "WARNING: not a WSDL based service. Skipping..."
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
  
  def process_parameter_xml(parameter_node, collection_to_find_annotatable, stats)
    # <parameterName>
    param_name = parameter_node.find_first("pd:parameterName").inner_xml
    
    # Some parameters in Feta are further "enhanced" with info, eg: "in0" becomes "in0:query_sequence1",
    # ie: an annotation (name alias) has been embedded.
    
    param_name_split = param_name.split(':')
    
    # Find the object that needs to be annotated
    parameter = collection_to_find_annotatable.find(:first, :conditions => { :name => param_name_split[0] })
    
    if parameter.nil?
      stats["total_xml_service_parameters_that_do_not_exist_in_service_now"].increment
      puts "WARNING: could not get SoapInput/SoapOutput matching parameter name '#{param_name_split[0]}' - most likely the service has changed. Skipping..."
    else
      # If a name alias was in the <parameterName> then store it as an annotation
      unless param_name_split[1].blank?
        puts "INFO: <parameterName> has a name alias embedded within it so storing this as a 'name' annotation (ie: name alias) on the SoapInput/SoapOutput."
        create_annotation(parameter, "name", param_name_split[1], stats)  
      end
      
      # <parameterDescription>
      param_desc_text = parameter_node.find_first("pd:parameterDescription").inner_xml
      create_annotation(parameter, "description", param_desc_text, stats) unless param_desc_text.blank?
      
      # <parameterFormat>
      parameter_format_node = parameter_node.find_first("pd:parameterFormat")
      unless parameter_format_node.nil?
        val = parameter_format_node.inner_xml
        create_annotation(parameter, "<http://www.mygrid.org.uk/mygrid-moby-service#objectType>", val, stats, true)
        create_annotation(parameter, "tag", val, stats, true)
      end
  
      # <collectionSemanticType>
      collection_semantic_type_node = parameter_node.find_first("pd:collectionSemanticType")
      unless collection_semantic_type_node.nil?
        val = collection_semantic_type_node.inner_xml
        create_annotation(parameter, "<http://www.mygrid.org.uk/mygrid-moby-service#hasParameterType>", val, stats, true)
        create_annotation(parameter, "tag", val, stats, true)
      end
      
      # <semanticType>
      semantic_type_node = parameter_node.find_first("pd:semanticType")
      unless semantic_type_node.nil?
        val = semantic_type_node.inner_xml
        create_annotation(parameter, "<http://www.mygrid.org.uk/mygrid-moby-service#inNamespaces>", val, stats, true)
        create_annotation(parameter, "tag", val, stats, true)
      end
    end
  end
  
  def create_annotation(annotatable, attribute, value, stats, is_ontological_term=false)
    annotatable_type = annotatable.class.name
    
    value_type = "String"
    
    # Preprocess value
    if is_ontological_term
      value = "<" + value + ">" unless value.starts_with?('<') and value.ends_with?('>')
      value_type = "URI"
    else
      value = CGI.unescapeHTML(value)
    end
    
    ann = Annotation.new(:attribute_name => attribute,
                         :value => value,
                         :value_type => value_type,
                         :source_type => "Agent",
                         :source_id => @agent.id,
                         :annotatable_type => annotatable_type,
                         :annotatable_id => annotatable.id)

    if ann.save
      stats["total_annotations_new"].increment
      puts "INFO: annotation successfully created:"
      puts format_annotation_info(annotatable_type, annotatable.id, attribute, value, value_type)
    else
      # Check if it failed because of duplicate...
      if ann.errors.full_messages.include?("This annotation already exists and is not allowed to be created again.")
        stats["total_annotations_already_exist"].increment
        puts "INFO: duplicate annotation detected so not storing it again. Annotation is:"
        puts format_annotation_info(annotatable_type, annotatable.id, attribute, value,value_type)
      else
        stats["total_annotations_failed"].increment
        puts "ERROR: creation of annotation failed! Errors: #{ann.errors.full_messages.to_sentence}. Check Rails logs for more info. Annotation is:"
        puts format_annotation_info(annotatable_type, annotatable.id, attribute, value, value_type)
      end
    end
  end
  
  def format_annotation_info(annotatable_type, annotatable_id, attribute, value, value_type)
    return "\tAnnotatable: #{annotatable_type} (ID: #{annotatable_id}) \n" +
           "\tAttribute name: #{attribute} \n" +
           "\tValue: #{value} \n" +
           "\tValue type: #{value_type}"
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
