#!/usr/bin/env ruby

# This script cleans up any services that were imported from SeekDa but are deemed not relevant to the BioCatalogue.
# E.g.: https://seekda.com/search_api?q=provider:ebi.ac.uk&p=0&numberOfResults=100
#
#
# Usage: seekda_cleanup [options]
#
#    -e, --environment=name           Specifies the environment to run this import script under (test|development|production).
#                                     Default: development
#
#    -h, --help                       Show this help message.
#
#    -t, --test                       Run the script in test mode (so won't actually store anything in the db and will only go through one keyword and one tag).
#
# 
# Examples of running this script:
#
#  ruby seekda_import.rb                <- runs the script on the development database.
#
#  ruby seekda_import.rb -e production  <- runs the script on the production database.
#
#  ruby seekda_import.rb -t             <- runs the script on the development database, in test mode (so no data is written to the db).
#
#  ruby seekda_import.rb -h             <- displays help text for this script.  
#
#
# NOTE (1): $stdout has been redirected to '{RAILS_ROOT}/log/seekda_cleanup_{current_time}.log' so you won't see any normal output in the console.
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

class SeekDaCleaner
  
  attr_accessor :options, :registry_source, :unwanted_wsdls, :unwanted_providers
  
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
      
      opts.on("-t", "--test", "Run the script in test mode (so won't actually store anything in the db and will only go through one keyword and one tag).") { @options[:test] = true }
    
      opts.parse!
    end
    
    # Start the Rails app
    
    ENV["RAILS_ENV"] = @options[:environment]
    RAILS_ENV.replace(@options[:environment]) if defined?(RAILS_ENV)
    
    require File.join(File.dirname(__FILE__), '..', '..', 'config', 'environment')
    
    # Get the Registry model object we will be using as the annotation source
    @registry_source = Registry.find_by_name("seekda")
    
    if @registry_source.nil?
      raise "Could not find the Registry entry for SeekDa"
    end
    
    # Set up list of unwanted things...
    @unwanted_wsdls = [ "http://appc22.rdg.ac.uk/SPICE/services/CASWebService?wsdl" ]
    @unwanted_providers = ["128.192.66.83",
                           "194.203.47.11",
                           "admin.excedent.com",
                           "api.ebay.com",
                           "api.echo.nasa.gov",
                           "api.eurocv.eu",
                           "api.verticalresponse.com",
                           "asptest.de",
                           "authors.aspalliance.com",
                           "brinsy.com",
                           "ccbay.tamucc.edu",
                           "coa.berkeley.edu",
                           "deepsightinfo.symantec.com",
                           "demo.avectra.com",
                           "gateway.englandnet.co.uk",
                           "his02.usu.edu",
                           "his03.geol.umt.edu",
                           "iaspub.epa.gov",
                           "in2test.lsi.uniovi.es",
                           "integration.services.7-5.identifythebest.com",
                           "interop.cmiservices.org",
                           "kbyte.ru",
                           "lcdnl.co.uk",
                           "marx.uni-mb.si",
                           "mx2.lokasoft.com",
                           "myopenlink.net",
                           "ntu-cg.ntu.edu.sg",
                           "ohrwurm.net",
                           "opendap.co-ops.nos.noaa.gov",
                           "ppc22.rdg.ac.uk",
                           "projects.dnv.com",
                           "rodeo.lemontech.cl",
                           "salut.gencat.net",
                           "soap.apm-internet.net",
                           "testbed.hr-xml.org",
                           "validator2.addressdoctor.com",
                           "webapps.datafed.net",
                           "webservices.cultuurweb.be",
                           "webservices.serviceu.com",
                           "webservicesls.socard.nl",
                           "ws1.webservices.nl",
                           "ws.strikeiron.com",
                           "wtcservice.trendmicro.com",
                           "www.2sms.com",
                           "www.artselect.artikelbeheer.nl",
                           "www.billmiami.com",
                           "www.bmbconnect.org",
                           "www.contrex.ch",
                           "www.eqsl.cc",
                           "www.gemx.org",
                           "www.ippages.com",
                           "www.irdat.regione.fvg.it",
                           "www.kintera.com",
                           "www.offentligajobb.se",
                           "www.salesforce.com",
                           "www.sercotelhoteles.com",
                           "www.spk.gov.tr",
                           "www.teleprior.eu",
                           "www.tradedate.com",
                           "www.weather.gov",
                           "www.webservicex.net",
                           "www.xatanet.net",
                           "www.xignite.com",
                           "xatanet.net" ]

  end
  
  def run
    
    puts "=> Booting SeekDa cleanup process. Running on #{@options[:environment]} database." 
    
    if @options[:test]
      puts ""
      puts "*****************************************************************************************"
      puts "NOTE: you have asked me to run in test mode, so I won't write/delete any data in the db."
      puts "*****************************************************************************************"
    end
    
    # Variables for statistics
    stats = { }
    stats["total_services_deleted"] = Counter.new
    stats["ids_of_services_deleted"] = [ ]
    
    begin
      Registry.transaction do
        
        # Go through unwanted WSDLs...
        
        @unwanted_wsdls.each do |unwanted_wsdl|
          
          puts ""
          puts ">> Searching for service with WSDL: '#{unwanted_wsdl}'"
          
          existing = SoapService.find(:all, :conditions => { :wsdl_location => unwanted_wsdl })
          
          puts "> Found #{existing.length}. Deleting the ones from SeekDa..."
          
          unless existing.blank?
            existing.each do |s|
              service = s.service
              if service.submitter_type == "Registry" and service.submitter_id == @registry_source.id
                puts "INFO: deleting service with ID: #{service.id}, and name: #{service.name}."
                stats["ids_of_services_deleted"] << service.id
                service.destroy
              end
            end
          end
          
        end
        
        # Go through unwanted providers...
        
        @unwanted_providers.each do |unwanted_provider|
          
          puts ""
          puts ">> Searching for services with provider '#{unwanted_provider}'"
          
          existing = Service.find(:all, 
                                  :conditions => { :service_deployments => { :service_providers => { :name => unwanted_provider } } }, 
                                  :joins => [ { :service_deployments => :provider } ])   
          
          puts "> Found #{existing.length}. Deleting the ones from SeekDa..."
          
          unless existing.blank?
            existing.each do |s|
              if s.submitter_type == "Registry" and s.submitter_id == @registry_source.id
                puts "INFO: deleting service with ID: #{s.id}, and name: #{s.name}."
                stats["ids_of_services_deleted"] << s.id
                s.destroy
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
      puts ">> ERROR: exception occured and transaction has been rolled back. Exception:"
      puts ex.message
      puts ex.backtrace.join("\n")
    end
  
    print_stats(stats)
    
  end
  
  def print_stats(stats)
    stats["ids_of_services_deleted"].sort!
    
    stats["total_services_deleted"] = stats["ids_of_services_deleted"].length
    
    puts ""
    puts ""
    puts "Stats:"
    puts "------"
    
    puts "Providers deemed not relevant (#{@unwanted_providers.length}) - #{@unwanted_providers.to_sentence}"
    puts "WSDLs deemed not relevant (#{@unwanted_wsdls.length}) - #{@unwanted_wsdls.to_sentence}"
    
    puts ""
    
    stats.sort.each do |h|
      if h[1].is_a? Array
        puts "#{h[0].humanize} = #{h[1].to_sentence}"
      else
        puts "#{h[0].humanize} = #{h[1].to_s}"  
      end
    end
  end
end

# Redirect $stdout to log file
puts "Redirecting output of $stdout to log file: '{RAILS_ROOT}/log/seekda_cleanup_{current_time}.log' ..."
$stdout = File.new("log/seekda_cleanup_#{Time.now.strftime('%Y%m%d-%H%M')}.log", "w")
$stdout = File.new(File.join(File.dirname(__FILE__),'..', '..', 'log', "seekda_cleanup_#{Time.now.strftime('%Y%m%d-%H%M')}.log"), "w")
$stdout.sync = true

puts Benchmark.measure { SeekDaCleaner.new(ARGV.clone).run }

# Reset $stdout
$stdout = STDOUT