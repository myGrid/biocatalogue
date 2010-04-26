#!/usr/bin/env ruby

# This script is used to update the descriptions of BioMoby services.
# It follows the rule that: all BioMoby services that have one operation 
# should "inherit" the description from the parent SoapService (ie: copy over the annotation).
#
#
# Usage: biomoby_descriptions [options]
#
#    -e, --environment=name           Specifies the environment to run this script under (test|development|production).
#                                     Default: development
#
#    -h, --help                       Show this help message.
#
#    -t, --test                       Run the script in test mode (so won't actually store anything in the db).
#
# 
# Examples of running this script:
#
#  ruby biomoby_descriptions.rb                <- runs the script on the development database.
#
#  ruby biomoby_descriptions.rb -e production  <- runs the script on the production database.
#
#  ruby biomoby_descriptions.rb -t             <- runs the script on the development database, in test mode (so no data is written to the db).
#
#  ruby biomoby_descriptions.rb -h             <- displays help text for this script.  
#
#
# NOTE (1): $stdout has been redirected to '{RAILS_ROOT}/log/biomoby_descriptions_{current_time}.log' so you won't see any normal output in the console.
#

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

class BioMobyDescriptions
  
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
    @rules[:wsdl_location] = [ "http://biomoby.org/services%", 
                               "%getMOBYWSDL%" ]
    
  end
  
  def run
    
    puts ""
    puts ""
    puts "=> Booting BioMoby Descriptions process. Running on #{@options[:environment]} database." 
    
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
    stats["total_services_processed"] = Counter.new
    stats["total_soap_services_with_one_operation"] = Counter.new
    stats["total_soap_services_without_descriptions"] = Counter.new
    stats["services_without_descriptions_ids"] = [ ]
    
    begin
      Service.transaction do
        
        @rules.each do |rule_key, rule_specs|
        
          puts ""
          puts ">> Processing rule: #{rule_key}"
        
          case rule_key
            when :wsdl_location
              
              rule_specs.each do |text, tag_name|
              
                puts ""
                puts "> Processing services that have a WSDL location of '#{text}'"
              
                soap_services = SoapService.find(:all, :conditions => [ "wsdl_location LIKE ?", text ])
                
                soap_services.each do |ss|
                  service = ss.service
                  
                  stats["total_services_processed"].increment
                  
                  puts "INFO: checking to see if description is required to be set on the SoapOperation for Service '#{service.name}' (ID: #{service.id})"
                  
                  # Now if the SoapService only has one operation, then copy over the description from the SoapService (if available).
                  if ss.soap_operations.length == 1
                    stats["total_soap_services_with_one_operation"].increment
                    
                    desc = ss.description
                    desc = ss.annotations_with_attribute("description").first.try(:value) if desc.blank?
                    
                    if desc.blank?
                      stats["total_soap_services_without_descriptions"].increment
                      stats["services_without_descriptions_ids"] << service.id
                    else
                      create_annotation(op = ss.soap_operations.first, "description", desc, stats)
                    end
                  end
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
puts "Redirecting output of $stdout to log file: '{RAILS_ROOT}/log/biomoby_descriptions_{current_time}.log' ..."
$stdout = File.new(File.join(File.dirname(__FILE__),'..', '..', 'log', "biomoby_descriptions_#{Time.now.strftime('%Y%m%d-%H%M')}.log"), "w")
$stdout.sync = true

puts Benchmark.measure { BioMobyDescriptions.new(ARGV.clone).run }

# Reset $stdout
$stdout = STDOUT