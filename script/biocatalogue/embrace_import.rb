#!/usr/bin/env ruby

# This script imports the data from the EMBRACE directory (which should be in the {RAILS_ROOT}/data/embrace) directory.
#
#
# Usage: embrace_import [options]
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
#  ruby embrace_import.rb                <- runs the script on the development database.
#
#  ruby embrace_import.rb -e production  <- runs the script on the production database.
#
#  ruby embrace_import.rb -t             <- runs the script on the development database, in test mode (so no data is written to the db).
#
#  ruby embrace_import.rb -h             <- displays help text for this script.  
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
  
  include Singleton

  def intialize
  
end

class EmbraceImporter
  
  attr_accessor :options, :data, :registry
  
  def initialize(args)
    @options = {
      :environment => (ENV['RAILS_ENV'] || "development").dup,
    }
    
    args.options do |opts|
      opts.on("-e", "--environment=name", String,
              "Specifies the environment to run this script under (test|development|production).",
              "Default: development") { |v| @options[:environment] = v }
    
      opts.separator ""
    
      opts.on("-h", "--help", "Show this help message.") { puts opts; exit }
      
      opts.on("-t", "--test", "Run the script in test mode (so won't actually store anything in the db).") { @options[:test] = true }
    
      opts.parse!
    end
    
    # Load up the data
    @data = EmbraceData.instance
    
    # Start the Rails app
    
    ENV["RAILS_ENV"] = @options[:environment]
    RAILS_ENV.replace(@options[:environment]) if defined?(RAILS_ENV)
    
    require File.join(File.dirname(__FILE__), '..', '..', 'config', 'environment')
    
    # Get or create the EMBRACE Registry registry object, which we will be using as the annotation and submitter source...
    @registry = Registry.find_by_name("embrace")
    
    if @registry.nil?
      @registry = Registry.create(:name => "embrace",
                                  :display_name => "The EMBRACE Registry",
                                  :homepage => "http://www.embraceregistry.net/")
    end
    
  end
  
  def run
    
    puts "=> Booting EMBRACE import process. Running on #{@options[:environment]} database." 
    
    if @options[:test]
      puts ""
      puts "*****************************************************************************************"
      puts "NOTE: you have asked me to run in test mode, so I won't write/delete any data in the db."
      puts "*****************************************************************************************"
    end
    
    # Variables for statistics
    stats = { }
    stats["total_annotations_new"] = Counter.new
    stats["total_annotations_already_exist"] = Counter.new
    stats["total_annotations_failed"] = Counter.new
    
    begin
      
      # First the users...
      
      User.transaction do
        
          puts ""
          puts ">> Processing user #{rule_key}"
        
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
$stdout = File.new(File.join(File.dirname(__FILE__),'..', '..', 'log', "embrace_import_#{Time.now.strftime('%Y%m%d-%H%M')}.log"), "w")
$stdout.sync = true

#puts Benchmark.measure { EmbraceImporter.new(ARGV.clone).run }

# Reset $stdout
$stdout = STDOUT