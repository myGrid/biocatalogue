#!/usr/bin/env ruby

# This script imports the data from the EMBRACE registry into BioCatalogue.
# It will use a snapshot of the data, in the form of 3 XML files:
# - user.xml
# - services.xml
# - tags.xml
#
# These files should be obtained from the appropriate source and stored somewhere locally ('source directory').
#
#
# Usage: embrace_import [options]
#    -s, --source=source              The source directory for the EMBRACE data files that need to be imported.
#                                     Default: {app_root}/embrace
#
#    -e, --environment=name           Specifies the environment to run this import script under (test|development|production).
#                                     Default: development
#
#    -h, --help                       Show this help message.
#
#    -t, --test                       Run the script in test mode (so won't actually store anything in the db) and only processes some of the data.
#
# 
# Examples of running this script:
#
#  ruby embrace_import.rb -s "/home/jits/embrace/"                <- runs the script on the development database, using the source files from "/home/jits/embrace/" (absolute path).
#
#  ruby embrace_import.rb -s "./../../embrace/"                   <- runs the script on the development database, using the source files from "./../../embrace/" (relative path; which would look for the 'embrace' folder in the folder 2 levels above the current folder). 
#
#  ruby embrace_import.rb -e production                           <- runs the script on the production database, using the source files from the default location of "{app_root}/embrace".
#
#  ruby embrace_import.rb -e production -s "/home/jits/embrace/"  <- runs the script on the production database, using the source files from "/home/jits/embrace/".
#
#  ruby embrace_import.rb -s "/home/jits/embrace/" -t             <- runs the script on the development database, using the source files from "/home/jits/embrace/", and in test mode (so no data is written to the db).
#
#  ruby embrace_import.rb -h                                      <- displays help text for this script.  
#
#
# NOTE (1): $stdout has been redirected to '{Rails.root}/log/embrace_import_{current_time}.log' so you won't see any normal output in the console.
#
#
# Depedencies:
# - Rails (v2.3.2)

require 'rubygems'
require 'optparse'
require 'benchmark'

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
  
  def to_s
    @count
  end
end

class EmbraceData
  
  attr_accessor :users, :services

  def initialize(source_path, test_mode=false)
    
    puts ""
    puts ""
    puts "=> Loading up EMBRACE data..."
    
    users_path = File.join(source_path, 'users.xml')
    services_path = File.join(source_path, 'services.xml')
    tags_path = File.join(source_path, 'tags.xml')
    
    user_email_excludes = [ 'embrace@utopia.cs.man.ac.uk' ]
    
    tag_excludes = [ 'other' ]
    
    # Users
    
    puts ""
    puts ">> Loading users data from #{users_path}"
    
    raw_users_data = Hash.from_xml(IO.read(users_path))
    
    processed_users_data = { }
    
    raw_users_data['resultset']['row'].each do |row|
      user = row['field']

      # Only take activated users
      if user[12] == "1"
        id = user[0].to_s
        email = user[3]
        name = user[1]
        
        unless email.blank? or user_email_excludes.include?(email.downcase)
          processed_users_data[id] = {
            :display_name => name,
            :email => email,
          }
        end
      end
    end
    
    @users = processed_users_data
    
    puts "> #{@users.length} users found (#{raw_users_data['resultset']['row'].length} in XML file)"
    
    
    # Services
    
    puts ""
    puts ">> Loading services data from #{services_path}"
    
    raw_services_data = Hash.from_xml(IO.read(services_path))
    
    processed_services_data = { }
    
    raw_services_data['resultset']['row'].each do |row|
      service = row['field']
      
      id = service[0].to_s
      wsdl_url = (service[7].is_a?(String) ? service[7] : nil)
      das_url = (service[8].is_a?(String) ? service[8] : nil)
      rest_url = (service[9].is_a?(String) ? service[9] : nil)
      user_id = service[13].to_s
      
      name = (service[2].is_a?(String) ? service[2] : nil)
      description = (service[3].is_a?(String) ? CGI.unescapeHTML(service[3]) : nil)
      documentation_url = (service[6].is_a?(String) ? service[6] : nil)
      version = (service[1].is_a?(String) ? service[1] : nil)
      
      unless processed_services_data.has_key?(id)
        processed_services_data[id] = {
          :wsdl_url => wsdl_url,
          :das_url => das_url,
          :rest_url => rest_url,
          :user_id => user_id,
          :annotations => {
            :display_name => name,
            :description => description,
            :documentation_url => documentation_url,
            :version => version,
          }
        }
      end
    end
    
    @services = processed_services_data
    
    puts "> #{@services.length} services found (#{raw_services_data['resultset']['row'].length} in XML file)"
    
    
    # Tags (need to be added to services)
    
    puts ""
    puts ">> Loading tags data from #{tags_path}"
    
    raw_tags_data = Hash.from_xml(IO.read(tags_path))
    
    tags_count = 0
    
    raw_tags_data['resultset']['row'].each do |row|
      tag = row['field']
      
      s_id = tag[1].to_s
      s = @services[s_id]
      
      if s.blank?
        puts "> ERROR: tag has a service ID that wasn't found in the services data - the EMBRACE service ID is #{s_id}"
      else
        tag_name = tag[2]
        unless tag_excludes.include?(tag_name.downcase)
          if s[:annotations].has_key?(:tag)
            s[:annotations][:tag] << tag_name
          else
            s[:annotations][:tag] = [ tag_name ]
          end
          
          tags_count += 1
        end
      end
    end
    
    puts "> #{tags_count} tags added to services data (#{raw_tags_data['resultset']['row'].length} found in XML file)"
    
#    puts ""
#    puts "@users = "
#    puts @users.inspect
#    
#    puts ""
#    puts "@services = "
#    puts @services.inspect
    
    # If test mode, do only 5 services
    if test_mode
      @services.keys[5..-1].each do |k|
        @services.delete(k)
      end
    end
    
  end
  
end

class EmbraceImporter
  
  attr_accessor :options, :data, :registry_source, :biocat_agent
  
  def initialize(args)
    @options = {
      :test        => false,
      :source      => File.join(File.dirname(__FILE__), '..', '..', 'embrace'),
      :environment => (ENV['RAILS_ENV'] || "development").dup,
    }
    
    args.options do |opts|
      opts.on("-s", "--source=source", String, "The source directory for the EMBRACE data files that need to be imported.", "Default: {app_root}/embrace") { |v| @options[:source] = v }
      opts.on("-e", "--environment=name", String,
              "Specifies the environment to run this import script under (test|development|production).",
              "Default: development") { |v| @options[:environment] = v }
    
      opts.separator ""
    
      opts.on("-h", "--help", "Show this help message.") { puts opts; exit }
      
      opts.on("-t", "--test", "Run the script in test mode (so won't actually store anything in the db) and only processes some of the data.") { @options[:test] = true }
    
      opts.parse!
    end
    
    # Start the Rails app
    
    ENV["RAILS_ENV"] = @options[:environment]
    RAILS_ENV.replace(@options[:environment]) if defined?(RAILS_ENV)
    
    require File.join(File.dirname(__FILE__), '..', '..', 'config', 'environment')
    
    # Load up the data
    @data = EmbraceData.new(@options[:source], @options[:test])
    
    # Get or create the EMBRACE Registry registry object, which we will be using as the annotation and submitter source...
    @registry_source = Registry.find_by_name("embrace")
    if @registry_source.nil?
      @registry_source = Registry.create(:name => "embrace",
                                        :display_name => "The EMBRACE Registry",
                                        :homepage => "http://www.embraceregistry.net/")
    end
    
    # Get or create the BioCatalogue agent, which we will be using as the annotation source...
    @biocat_agent = Agent.find_by_name("biocatalogue")
    if @biocat_agent.nil?
      @biocat_agent = Agent.create(:name => "biocatalogue",
                                   :display_name => "BioCatalogue")
    end
    
  end
  
  def run
    
    puts ""
    puts ""
    puts "=> Booting EMBRACE import process. Running on #{@options[:environment]} database." 
    
    if @options[:test]
      puts ""
      puts "*****************************************************************************************"
      puts "NOTE: you have asked me to run in test mode, so I won't write/delete any data in the db."
      puts "*****************************************************************************************"
    end
    
    # Variables for statistics
    stats = { }
    stats["total_users_new"] = Counter.new
    stats["total_users_existed"] = Counter.new
    stats["ids_of_users_new"] = [ ]
    stats["ids_of_users_existing"] = [ ]
    stats["total_services_new"] = Counter.new
    stats["total_services_existed_and_updated"] = Counter.new
    stats["total_services_failed_to_create"] = Counter.new
    stats["total_services_were_soap"] = Counter.new
    stats["total_services_were_rest"] = Counter.new
    stats["total_annotations_new"] = Counter.new
    stats["total_annotations_already_exist"] = Counter.new
    stats["total_annotations_failed_to_create"] = Counter.new
    stats["total_annotations_deleted"] = Counter.new
    stats["total_annotations_updated"] = Counter.new
    stats["total_annotations_failed_to_update"] = Counter.new
    stats["ids_of_services_new"] = [ ]
    stats["ids_of_services_updated"] = [ ]
    
    
    begin
      
      User.transaction do
        
        # First the users...
        
        @data.users.each do |user_id, user|
        
          puts ""
          puts ">> Processing user '#{user[:display_name]}' (ID: #{user_id})"
          
          existing = User.find_by_email(user[:email])
          
          if existing
            puts "INFO: User already exists in the DB"
            stats["ids_of_users_existing"] << existing.id
            
            Relationship.create(:subject => existing, :predicate => "BioCatalogue:alsoIn", :object => @registry_source)
            existing.create_annotations({ "embrace_id" => user_id }, @biocat_agent)
          else
            u = User.new
            
            u.email = user[:email]
            u.email_confirmation = user[:email]
            
            temp_password = rand(100000000000000)
            u.password = temp_password
            u.password_confirmation = temp_password
            
            u.display_name = user[:display_name]
            u.receive_notifications = true
            
            if u.save
              u.activate!
              
              unless @options[:test]
                UserMailer.reset_password(u, "www.biocatalogue.org").deliver
              end
              
              puts "INFO: new user added to DB and a reset password email has been sent"
              stats["ids_of_users_new"] << u.id
              
              Relationship.create(:subject => u, :predicate => "BioCatalogue:origin", :object => @registry_source)
              u.create_annotations({ "embrace_id" => user_id }, @biocat_agent)
            else
              puts "ERROR: failed to save new user. Error(s): #{u.errors.full_messages.to_sentence}"
            end
          end
        end
        
        # Then the services...
        
        @data.services.each do |service_id, service|
        
          puts ""
          puts ">> Processing service '#{service[:annotations][:display_name]}' (ID: #{service_id})"
          
          submitter = nil
          
          unless service[:user_id].nil? or @data.users[service[:user_id]].nil?
            submitter = User.find_by_email(@data.users[service[:user_id]][:email])
          end
          
          biocat_service = nil
          
          if submitter.nil?
            stats["total_services_failed_to_create"].increment
            puts "ERROR: could not find submitter with Embrace ID: #{service[:user_id]}!"
          else
            if !service[:wsdl_url].blank?
              puts "INFO: SOAP service. Processing..."
              biocat_service = process_soap_service(service, submitter, stats)
            elsif !service[:rest_url].blank?
              puts "INFO: REST service. Processing..."
              biocat_service = process_rest_service(service, submitter, stats)
            elsif !service[:das_url].blank?
              puts "WARNING: DAS service. Cannot add this to the DB."
              stats["total_services_failed_to_create"].increment
            end
            
            if biocat_service
              biocat_service.create_annotations({ "embrace_id" => service_id }, @biocat_agent)
              Relationship.create(:subject => biocat_service, :predicate => "BioCatalogue:embraceOriginalSubmitter", :object => submitter)
            end
          end
          
        end
        
        if @options[:test]
          raise "You asked me to test, so I am rolling back your transaction so nothing is stored in the db..."
        end
        
      end
    rescue Exception => ex
      puts ""
      puts ">> ERROR: exception occured and transaction has been rolled back. Exception:"
      puts ex.message
      puts ex.backtrace.join("\n")
    end
    
    print_stats(stats)
    
  end
  
  def print_stats(stats)
    stats["ids_of_services_new"].sort!
    stats["ids_of_services_updated"].sort!
    stats["ids_of_users_new"].sort!
    stats["ids_of_users_existing"].sort!
    
    stats["total_services_new"] = stats["ids_of_services_new"].length
    stats["total_services_existed_and_updated"] = stats["ids_of_services_updated"].length
    stats["total_users_new"] = stats["ids_of_users_new"].length
    stats["total_users_existed"] = stats["ids_of_users_existing"].length
    
    puts ""
    puts ""
    puts "Stats:"
    puts "------"
    
    puts ""
    
    stats.sort.each do |h|
      if h[1].is_a? Array
        puts "#{h[0].humanize} = #{h[1].to_sentence}"
      else
        puts "#{h[0].humanize} = #{h[1].to_s}"  
      end
    end
  end
  
  def process_soap_service(service, submitter, stats)
    final_service = nil
    
    stats["total_services_were_soap"].increment
    
    begin
    
      # Normalize WSDL URL
      wsdl_url = Addressable::URI.parse(service[:wsdl_url]).normalize.to_s
      
      soap_service = nil
      service_ok = true
  
      # Check if the service exists in the database and if not create it.
      #
      # NOTE: since we know that the duplication check for Soap Services currently 
      # doesn't take into account the endpoint, we can just provide a blank string for that. 
      if (existing_service = SoapService.check_duplicate(wsdl_url, "")).nil?
        # Doesn't exist, so new SoapService needs to be created...
                
        soap_service = SoapService.new(:wsdl_location => wsdl_url)
        new_service_success, s_data = soap_service.populate
        
        if new_service_success
          new_service_success = soap_service.submit_service(s_data["endpoint"], submitter, { })
          
          if new_service_success
            Relationship.create(:subject => soap_service.service(true), :predicate => "BioCatalogue:origin", :object => @registry_source)
            puts "INFO: new service (ID: #{soap_service.service.id}, WSDL URL: '#{wsdl_url}') successfully created!"
            stats["ids_of_services_new"] << soap_service.service.id
          else
            puts "ERROR: failed to carry out submit_service of SoapService object with WSDL URL '#{wsdl_url}' (ie: db has not been populated with the SoapService and associated objects). Check the relevant Rails log file for more info."
            service_ok = false
          end
        else
          puts "ERROR: failed to populate SoapService object from WSDL URL '#{wsdl_url}'. Error messages: #{soap_service.errors.full_messages.to_sentence}"
          service_ok = false
        end
      else
        # Exists, so update the submitters info and save, and then get the relevant SoapService object...
                
        puts "INFO: existing matching service found (ID: #{existing_service.id}, WSDL URL: '#{wsdl_url}', Submitter: #{BioCatalogue::Util.display_name(existing_service.submitter)})."
        
        unless stats["ids_of_services_new"].include?(existing_service.id) or stats["ids_of_services_updated"].include?(existing_service.id) 
          stats["ids_of_services_updated"] << existing_service.id
        end
        
        if existing_service.submitter == @registry_source
          unless existing_service.update_service_structure_submitter(submitter)
            puts "ERROR: failed to update the submitter of this service (ID: #{existing_service.id}) and it's child ServiceDeployments and ServiceVersions."
          end
          
          Relationship.create(:subject => existing_service, :predicate => "BioCatalogue:origin", :object => @registry_source)
        else
          Relationship.create(:subject => existing_service, :predicate => "BioCatalogue:alsoIn", :object => @registry_source)
        end
        
        existing_service.service_version_instances_by_type("SoapService").each do |si|
          soap_service = si if si.wsdl_location.downcase == wsdl_url.downcase
        end
      end
      
      # Continue adding any annotations etc
      if service_ok and !soap_service.nil?
        sync_annotations(service, soap_service, submitter, stats)
        final_service = soap_service.service
      else
        puts "ERROR: creation/updation of this service failed!"
        stats["total_services_failed_to_create"].increment
      end
    
    rescue Exception => ex
      stats["total_services_failed_to_create"].increment
      puts ""
      puts "> ERROR: exception whilst processing SOAP service. Exception:"
      puts ex.message
      puts ex.backtrace.join("\n")
    end
    
    return final_service
  end
  
  def process_rest_service(service, submitter, stats)
    final_service = nil
    
    stats["total_services_were_rest"].increment
    
    begin
    
      endpoint = Addressable::URI.parse(service[:rest_url]).normalize.to_s
      
      rest_service = nil
      service_ok = true
      
      if (existing_service = RestService.check_duplicate(endpoint)).nil?
        # Doesn't exist, so new RestService needs to be created...
        
        rest_service = RestService.new
        rest_service.name = service[:annotations][:display_name]
        service[:annotations].delete(:display_name)
        
        new_service_success = rest_service.submit_service(endpoint, submitter, { })
        
        if new_service_success
          Relationship.create(:subject => rest_service.service(true), :predicate => "BioCatalogue:origin", :object => @registry_source)
          puts "INFO: new service (ID: #{rest_service.service.id}, Endpoint URL: '#{endpoint}') successfully created!"
          stats["ids_of_services_new"] << rest_service.service.id
        else
          puts "ERROR: failed to carry out submit_service of RestService object with endpoint URL '#{endpoint}' (ie: db has not been populated with the RestService and associated objects). Check the relevant Rails log file for more info."
          service_ok = false
        end
      else
        # Exists, so update the submitters and save, and then get the relevant RestService object...
        
        puts "INFO: existing matching service found (ID: #{existing_service.id}, Endpoint URL: '#{endpoint}', Submitter: #{BioCatalogue::Util.display_name(existing_service.submitter)})."
        
        unless stats["ids_of_services_new"].include?(existing_service.service.id) or stats["ids_of_services_updated"].include?(existing_service.id) 
          stats["ids_of_services_updated"] << existing_service.service.id
        end
        
        if existing_service.submitter == @registry_source
          unless existing_service.update_service_structure_submitter(submitter)
            puts "ERROR: failed to update the submitter of this service (ID: #{existing_service.id}) and it's child ServiceDeployments and ServiceVersions."
          end
          
          Relationship.create(:subject => existing_service, :predicate => "BioCatalogue:origin", :object => @registry_source)
        else
          Relationship.create(:subject => existing_service, :predicate => "BioCatalogue:alsoIn", :object => @registry_source)
        end
        
        existing_service.service_version_instances_by_type("RestService").each do |si|
          rest_service = si
        end
      end
      
      # Continue adding any annotations etc
      if service_ok and !rest_service.nil?
        sync_annotations(service, rest_service, submitter, stats)
        final_service = rest_service.service
      else
        puts "ERROR: creation/updation of this service failed!"
        stats["total_services_failed_to_create"].increment
      end
    
    rescue Exception => ex
      stats["total_services_failed_to_create"].increment
      puts ""
      puts "> ERROR: exception whilst processing REST service. Exception:"
      puts ex.message
      puts ex.backtrace.join("\n")
    end
    
    return final_service
  end
  
  def sync_annotations(service_data, service_instance_obj, submitter, stats)
    service_data[:annotations].each do |attribute, value|
      unless value.blank?
        case attribute
          when :display_name
            sync_annotation(service_instance_obj.service, attribute, value, submitter, stats)
          when :description, :documentation_url
            sync_annotation(service_instance_obj, attribute, value, submitter, stats)
          when :version
            sync_annotation(service_instance_obj.service_version, attribute, value, submitter, stats)
          when :tag
            value.each do |v|
              sync_annotation(service_instance_obj.service, attribute, v, submitter, stats)
            end
        end
      end
    end
  end
  
  def sync_annotation(annotatable, attribute, value, original_submitter, stats)
    annotation = nil
    
    # Check for an existing annotation made previously with the source being the EMBRACE Registry object
    existing = annotatable.annotations.find(:first, 
                                            :conditions => { :annotation_attributes => { :name => attribute.to_s }, 
                                                             :value => value,
                                                             :source_type => @registry_source.class.name,
                                                             :source_id => @registry_source.id }, 
                                            :joins => [ :attribute ])

    if existing.nil?
      puts "INFO: need to create new annotation"
      
      # Special rules apply...
      case attribute
        when :display_name
          
          # Check for an alternative name with that value
          
          existing = annotatable.annotations.find(:first, 
                                                  :conditions => { :annotation_attributes => { :name => "alternative_name" }, 
                                                                   :value => value,
                                                                   :source_type => @registry_source.class.name,
                                                                   :source_id => @registry_source.id }, 
                                                  :joins => [ :attribute ])
          
          if existing.nil?
            annotation = create_annotation(original_submitter, annotatable, attribute, value, stats)
          else
            existing.source = original_submitter
            existing.attribute_name = "display_name"
            if existing.save
              puts "INFO: successfully converted an alternative_name annotation to a display_name annotation and also updated the source to the original submitter from the EMBRACE registry"
            else
              puts "ERROR: failed to convert an alternative_name annotation to a display_name annotation. Errors: #{existing.errors.full_messages.to_sentence}"              
            end
          end
          
        else
          annotation = create_annotation(original_submitter, annotatable, attribute, value, stats)
      end
    else
      annotation = existing
      
      # Update the source of the annotation if required
      unless annotation.source == original_submitter
        puts "INFO: need to update the source of an existing annotation that had the source set to the EMBRACE Registry"
        
        annotation.source = original_submitter
        if annotation.save
          puts "INFO: annotation successfully updated!"
          stats["total_annotations_updated"].increment
        else
          puts "WARNING: failed to update the source of annotation (ID: #{annotation.id})"
          stats["total_annotations_failed_to_update"].increment
        end
      else
        puts "INFO: don't need to update the source of an existing annotation because it is already the right one"
      end
    end
    
    unless annotation.nil?
      Relationship.create(:subject => annotation, :predicate => "BioCatalogue:origin", :object => @registry_source)
    end
  end
  
  def create_annotation(source, annotatable, attribute, value, stats, is_ontological_term=false)
    annotatable_type = annotatable.class.name
    source_type = source.class.name
    
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
                         :source_type => source_type,
                         :source_id => source.id,
                         :annotatable_type => annotatable_type,
                         :annotatable_id => annotatable.id)

    if ann.save
      stats["total_annotations_new"].increment
      puts "INFO: annotation successfully created:"
      puts format_annotation_info(source_type, source.id, annotatable_type, annotatable.id, attribute, value, value_type)
      
      return ann
    else
      # Check if it failed because of duplicate...
      if ann.errors.full_messages.include?("This annotation already exists and is not allowed to be created again.")
        stats["total_annotations_already_exist"].increment
        puts "INFO: duplicate annotation detected so not storing it again. Annotation is:"
        puts format_annotation_info(source_type, source.id, annotatable_type, annotatable.id, attribute, value,value_type)
      else
        stats["total_annotations_failed_to_create"].increment
        puts "ERROR: creation of annotation failed! Errors: #{ann.errors.full_messages.to_sentence}. Check Rails logs for more info. Annotation is:"
        puts format_annotation_info(source_type, source.id, annotatable_type, annotatable.id, attribute, value, value_type)
      end
      
      return nil
    end
    
  end
  
  def format_annotation_info(source_type, source_id, annotatable_type, annotatable_id, attribute, value, value_type)
    return "\tAnnotatable: #{annotatable_type} (ID: #{annotatable_id}) \n" +
           "\tAttribute name: #{attribute} \n" +
           "\tSource: #{source_type} (ID: #{source_id}) \n" +
           "\tValue: #{value} \n" +
           "\tValue type: #{value_type}"
  end
  
end

# Redirect $stdout to log file
puts "Redirecting output of $stdout to log file: '{Rails.root}/log/embrace_import_{current_time}.log' ..."
$stdout = File.new(File.join(File.dirname(__FILE__), '..', '..', 'log', "embrace_import_#{Time.now.strftime('%Y%m%d-%H%M')}.log"), "w")
$stdout.sync = true

puts Benchmark.measure { EmbraceImporter.new(ARGV.clone).run }

# Uncomment the lines below to test out just the data (remember to comment out the line above first)
#RAILS_ENV="production"
#require File.join(File.dirname(__FILE__), '..', '..', 'config', 'environment')
#puts EmbraceData.new(File.join(File.dirname(__FILE__), '..', '..', 'embrace'), false).inspect

# Reset $stdout
$stdout = STDOUT