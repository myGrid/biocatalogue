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
#    -t, --test                       Run the script in test mode (so won't actually store anything in the db).
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
# NOTE (1): $stdout has been redirected to '{RAILS_ROOT}/log/embrace_import_{current_time}.log' so you won't see any normal output in the console.
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

  def initialize(source_path, test_mode)
    
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
    
    raw_users_data['embrace']['de_users'].each do |de_users|
      unless de_users['mail'].blank? or user_email_excludes.include?(de_users['mail'])
        processed_users_data[de_users['uid']] = {
          :display_name => de_users['name'],
          :email => de_users['mail'],
          :activated_at => Time.now
        }
      end
    end
    
    @users = processed_users_data
    
    puts "> #{@users.length} users found (#{raw_users_data['embrace']['de_users'].length} in XML file)"
    
    
    # Services
    
    puts ""
    puts ">> Loading services data from #{services_path}"
    
    raw_services_data = Hash.from_xml(IO.read(services_path))
    
    processed_services_data = { }
    
    raw_services_data['embrace']['de_ws_service'].each do |de_ws_service|
      s_id = de_ws_service['nid']
      unless processed_services_data.has_key?(s_id)
        processed_services_data[s_id] = {
          :wsdl_url => de_ws_service['wsdl_url'],
          :das_url => de_ws_service['das_url'],
          :rest_url => de_ws_service['das_url'],
          :user_id => de_ws_service['uid'],
          :annotations => {
            :name => de_ws_service['title'],
            :documentation_url => de_ws_service['url'],
            :version => de_ws_service['version'],
          }
        }
      end
    end
    
    @services = processed_services_data
    
    puts "> #{@services.length} services found (#{raw_services_data['embrace']['de_ws_service'].length} in XML file)"
    
    
    # Tags (need to be added to services)
    
    puts ""
    puts ">> Loading tags data from #{tags_path}"
    
    raw_tags_data = Hash.from_xml(IO.read(tags_path))
    
    tags_count = 0
    
    raw_tags_data['embrace']['de_term_data'].each do |de_term|
      s_id = de_term['nid']
      s = @services[s_id]
      if s.blank?
        puts "> ERROR: tag has a service ID that wasn't found in the services data - service ID is #{s_id}"
      else
        tag_name = de_term['tagname']
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
    
    puts "> #{tags_count} tags added to services data (#{raw_tags_data['embrace']['de_term_data'].length} found in XML file)"
    
    # If test mode, only have 2 users and 2 services
    if test_mode
      @users.keys[2..-1].each do |k|
        @users.delete(k)
      end
      
      @services.keys[2..-1].each do |k|
        @services.delete(k)
      end
    end
    
  end
  
end

class EmbraceImporter
  
  attr_accessor :options, :data, :registry
  
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
      
      opts.on("-t", "--test", "Run the script in test mode (so won't actually store anything in the db).") { @options[:test] = true }
    
      opts.parse!
    end
    
    # Start the Rails app
    
    ENV["RAILS_ENV"] = @options[:environment]
    RAILS_ENV.replace(@options[:environment]) if defined?(RAILS_ENV)
    
    require File.join(File.dirname(__FILE__), '..', '..', 'config', 'environment')
    
    # Load up the data
    @data = EmbraceData.new(@options[:source], @options[:test])
    
    # Get or create the EMBRACE Registry registry object, which we will be using as the annotation and submitter source...
    @registry = Registry.find_by_name("embrace")
    
    if @registry.nil?
      @registry = Registry.create(:name => "embrace",
                                  :display_name => "The EMBRACE Registry",
                                  :homepage => "http://www.embraceregistry.net/")
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
    stats["total_annotations_new"] = Counter.new
    stats["total_annotations_already_exist"] = Counter.new
    stats["total_annotations_failed"] = Counter.new
    stats["ids_of_services_new"] = [ ]
    stats["ids_of_services_updated"] = [ ]
    
    # First the users...
    begin
      User.transaction do
        
        @data.users.each do |user_id, user|
        
          puts ""
          puts ">> Processing user '#{user[:display_name]}' (ID: #{user_id})"
          
          existing = User.find_by_email(user[:email])
          
          if existing
            puts "> INFO: User already exists in the DB"
            stats["ids_of_users_existing"] << existing.id
          else
            u = User.new(user)
            if u.save(false)
              puts "> INFO: new user added to DB!"
              stats["ids_of_users_new"] << u.id
            else
              puts "> ERROR: failed to save new user. Error(s): #{u.errors.full_messages.to_sentence}"
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
    
    # Then the services...
    begin
      Service.transaction do
        
        @data.services.each do |service_id, service|
        
          puts ""
          puts ">> Processing service '#{service[:annotations][:name]}' (ID: #{service_id})"
          
          if !service[:wsdl_url].nil?
            puts "INFO: WSDL based service. Processing..."
          elsif !service[:rest_url].nil?
            puts "INFO: REST service. Processing..."
          elsif !service[:das_url].nil?
            puts "WARNING: DAS service. Cannot add this to the DB."
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
                         :source_type => @registry.class.name,
                         :source_id => @registry.id,
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
puts "Redirecting output of $stdout to log file: '{RAILS_ROOT}/log/embrace_import_{current_time}.log' ..."
$stdout = File.new(File.join(File.dirname(__FILE__), '..', '..', 'log', "embrace_import_#{Time.now.strftime('%Y%m%d-%H%M')}.log"), "w")
$stdout.sync = true

puts Benchmark.measure { EmbraceImporter.new(ARGV.clone).run }

# Reset $stdout
$stdout = STDOUT