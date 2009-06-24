#!/usr/bin/env ruby

# This script tags certain services with certain tags, based on a set of rules.
# E.g.: services that have "http://biomoby.org/services" in their WSDL location(s) should be tagged with "BioMoby".
#
#
# Usage: auto_tagger [options]
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
#  ruby auto_tagger.rb                <- runs the script on the development database.
#
#  ruby auto_tagger.rb -e production  <- runs the script on the production database.
#
#  ruby auto_tagger.rb -t             <- runs the script on the development database, in test mode (so no data is written to the db).
#
#  ruby auto_tagger.rb -h             <- displays help text for this script.  
#
#
# NOTE (1): $stdout has been redirected to '{RAILS_ROOT}/log/auto_tagger_{current_time}.log' so you won't see any normal output in the console.
#
#
# Depedencies:
# - Rails (v2.2.2)

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

class AutoTagger
  
  attr_accessor :options, :biocat_agent, :rules
  
  def initialize(args)
    @options = {
      :environment => (ENV['RAILS_ENV'] || "development").dup,
    }
    
    args.options do |opts|
      opts.on("-e", "--environment=name", String,
              "Specifies the environment to run this cleanup script under (test|development|production).",
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
    
    # Get or create the BioCatalogue agent, which we will be using as the annotation source...
    @biocat_agent = Agent.find_by_name("biocatalogue")
    
    if @biocat_agent.nil?
      @biocat_agent = Agent.create(:name => "biocatalogue",
                                   :display_name => "BioCatalogue")
    end
    
    # Set up rules
    
    @rules = { }
    @rules[:wsdl_location] = { "http://biomoby.org/services%" => "BioMoby" }
    
  end
  
  def run
    
    puts "=> Booting Auto Tagger process. Running on #{@options[:environment]} database." 
    
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
      Service.transaction do
        
        @rules.each do |rule_key, rule_specs|
        
          puts ""
          puts ">> Processing rule: #{rule_key}"
        
          case rule_key
            when :wsdl_location
              
              rule_specs.each do |text, tag_name|
              
                puts ""
                puts "> Processing services that have a WSDL location of '#{text}' (will add tag '#{tag_name}')"
              
                soap_services = SoapService.find(:all, :conditions => [ "wsdl_location LIKE ?", text ])
                
                soap_services.each do |ss|
                  service = ss.service
                  
                  puts "INFO: adding tag '#{tag_name}' to service '#{service.name}' (ID: #{service.id})"
                  
                  create_annotation(service, "Tag", tag_name, stats)
                end
              
              end
              
            else
              puts ""
              puts ">> NO PROCESSING LOGIC FOR RULE: '#{rule_key.to_s}'"
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
                         :source_type => @biocat_agent.class.name,
                         :source_id => @biocat_agent.id,
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
puts "Redirecting output of $stdout to log file: '{RAILS_ROOT}/log/auto_tagger_{current_time}.log' ..."
$stdout = File.new(File.join(File.dirname(__FILE__),'..', '..', 'log', "auto_tagger_#{Time.now.strftime('%Y%m%d-%H%M')}.log"), "w")
$stdout.sync = true

puts Benchmark.measure { AutoTagger.new(ARGV.clone).run }

# Reset $stdout
$stdout = STDOUT