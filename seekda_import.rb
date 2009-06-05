#!/usr/bin/env ruby

# This script imports services through the SeekDa HTTP/XML API.
# E.g.: https://seekda.com/search_api?q=provider:ebi.ac.uk&p=0&numberOfResults=100
#
# A set of keywords are used to retrieve all bio based services.
#
#
# Usage: seekda_import [options]
#    -p, --password=password          The password to use for the SeekDa account that authenticates the API access (currently using the username 'biocatalogue-developers@rubyforge.org').
#                                     Default: nil (this is a required option!)
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
#  ruby seekda_import.rb -p "my_password"                 <- runs the script on the development database, using the password "my_password" for the SeekDa account.
#
#  ruby seekda_import.rb -p "my_password" -e production   <- runs the script on the production database, using the password "my_password" for the SeekDa account.
#
#  ruby seekda_import.rb -p "my_password" -t              <- runs the script on the development database, using the password "my_password" for the SeekDa account, and in test mode (so no data is written to the db).
#
#  ruby seekda_import.rb -h                               <- displays help text for this script.  
#
#
# NOTE (1): $stdout has been redirected to 'seekda_import.log' so you won't see any normal output in the console.
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
require 'system_timer'
require 'open-uri'
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
  
  def to_s
    @count
  end
end

class SeekDaImporter
  include LibXML
  
  attr_accessor :options, :username, :password, :registry_source, :franck, :keywords, :tags, :provider_excludes, :wsdl_excludes
  
  def initialize(args)
    @options = {
      :password    => nil,
      :environment => (ENV['RAILS_ENV'] || "development").dup,
    }
    
    args.options do |opts|
      opts.on("-p", "--password=password", String, "The password to use for the SeekDa account that authenticates the API access (currently using the username 'biocatalogue-developers@rubyforge.org').") { |v| @options[:password] = v }
      opts.on("-e", "--environment=name", String,
              "Specifies the environment to run this import script under (test|development|production).",
              "Default: development") { |v| @options[:environment] = v }
    
      opts.separator ""
    
      opts.on("-h", "--help", "Show this help message.") { puts opts; exit }
      
      opts.on("-t", "--test", "Run the script in test mode (so won't actually store anything in the db and will only go through one keyword and one tag).") { @options[:test] = true }
    
      opts.parse!
    end
    
    # Start the Rails app
      
    ENV["RAILS_ENV"] = @options[:environment]
    RAILS_ENV.replace(@options[:environment]) if defined?(RAILS_ENV)
    
    require File.dirname(__FILE__) + '/config/environment'
    
    # Get the Registry model object we will be using as the annotation source
    @registry_source = Registry.find_by_name("seekda")
    
    # Create the SeekDa registry entry if it doesn't exist
    if @registry_source.nil?
      @registry_source = Registry.create(:name => "seekda", 
                                         :display_name => "SeekDa",
                                         :homepage => "http://www.seekda.com")
    end
    
    # Get Franck!
    @franck = User.find_by_email("ytanoh@cs.man.ac.uk")
    
    # Set up keywords and tags to search on in SeekDa
    
    if @options[:test]
      @keywords = %w{ Oligonucleotides }
      @tags =     %w{ prediction }
    else
      @keywords = %w{ biology bioinformatics genomics gene protein genome genomic proteome proteomic DNA RNA Allele 
                      Metabolomics Transcriptomics Probe Reaction Oligonucleotides QTL Loci locus Nucleotide Phylogenetic 
                      Enzyme Microarray Pathway Primer Tissue Ligand SNPs Mutation Yeast Genotype Phenotype Organ Pathogen 
                      Virus Bacteria Eukaryotes prokaryotes  }
    
      @tags =     %w{ genetics DNA alignment bioinformatics gene genome prediction organism prediction protein sequence }
    end
    
    # Set username and password
    @username = "biocatalogue-developers@rubyforge.org"
    @password = @options[:password]
    
    # Set excludes
    @provider_excludes = [ "128.192.66.83", 
                           "194.203.47.11",
                           "excedent.com",
                           "ebay.com",
                           "nasa.gov",
                           "eurocv.eu",
                           "verticalresponse.com",
                           "asptest.de",
                           "aspalliance.com",
                           "brinsy.com",
                           "berkeley.edu",
                           "symantec.com",
                           "avectra.com",
                           "englandnet.co.uk",
                           "umt.edu",
                           "epa.gov",
                           "identifythebest.com",
                           "cmiservices.org",
                           "kbyte.ru",
                           "uni-mb.si",
                           "lokasoft.com",
                           "myopenlink.net",
                           "ntu.edu.sg",
                           "ohrwurm.net",
                           "rdg.ac.uk",
                           "dnv.com",
                           "lemontech.cl",
                           "gencat.net",
                           "apm-internet.net",
                           "hr-xml.org",
                           "addressdoctor.com",
                           "datafed.net",
                           "cultuurweb.be",
                           "serviceu.com",
                           "socard.nl",
                           "strikeiron.com",
                           "weather.gov",
                           "trendmicro.com",
                           "2sms.com",
                           "artikelbeheer.nl",
                           "billmiami.com",
                           "bmbconnect.org",
                           "contrex.ch",
                           "eqsl.cc",
                           "gemx.org",
                           "ippages.com",
                           "fvg.it",
                           "kintera.com",
                           "offentligajobb.se",
                           "salesforce.com",
                           "sercotelhoteles.com",
                           "spk.gov.tr",
                           "teleprior.eu",
                           "tradedate.com",
                           "weather.gov",
                           "webservicex.net",
                           "xatanet.net",
                           "xignite.com",
                           "xatanet.net",
                           "uniovi.es",
                           "webservices.nl",
                           "weather.gov",
                           "tamucc.edu",
                           "usu.edu",
                           "lcdnl.co.uk" ]
    
    @wsdl_excludes = [ "phoebus.cs.man.ac.uk",
                       "ppdev.vbi.vt.edu" ]
  end
  
  def run
    
    puts "=> Booting SeekDa to BioCatalogue import process. Running on #{@options[:environment]} database." 
    
    if @options[:test]
      puts ""
      puts "*********************************************************************************"
      puts "NOTE: you have asked me to run in test mode, so I won't write any data to the db"
      puts "and will only go through one keyword and one tag."
      puts "*********************************************************************************"
    end
    
    preconditions_met = true
    
    if @password.blank?
      puts ""
      puts ">> FATAL: no password provided."
      preconditions_met = false
    end
    
    if @franck.nil?
      puts ""
      puts ">> FATAL: Franck is nil! (He doesn't exist in the database)."
      preconditions_met = false
    end
    
    unless preconditions_met
      puts ""
      puts ">> FATAL: Not all preconditions met. Exiting..."
      return 1
    end
    
    # Variables for statistics
    stats = { }
    stats["total_services_found_in_seekda"] = Counter.new
    stats["total_services_new"] = Counter.new
    stats["total_services_existed"] = Counter.new
    stats["total_services_failed_to_create"] = Counter.new
    stats["total_services_excluded"] = Counter.new
    stats["total_annotations_new"] = Counter.new
    stats["total_annotations_already_exist"] = Counter.new
    stats["total_annotations_failed"] = Counter.new
    stats["ids_of_new_services"] = [ ]
    stats["ids_of_existing_services"] = [ ]
    
    base_uri = "https://seekda.com/search_api?"
    
    # Combine the keywords and tags into the appropriate queries
    queries = @keywords + @tags.map{|t| "tag:#{t}"}
    
    begin
      Registry.transaction do
        puts ""
        puts "=> Processing all keywords and tags to search for on SeekDa..."
          
        queries.each do |query|
          
          puts ""
          puts "----------------------------------------------------------"
          puts ">> Processing query '#{query}'..."
          puts "----------------------------------------------------------"
          
          # p=x in the SeekDa API actually means the item number, NOT page number.
          current_start_item_index = 0
          
          has_items = true
          
          query_services_count = 0
          
          while has_items
          
            url = "#{base_uri}q=#{query}&p=#{current_start_item_index}"
          
            puts ""
            puts "> [#{Time.now.strftime('%d/%m/%y %H:%M:%S')}] Attempting to fetch page #{current_start_item_index/10} of results (URL: #{url})"
            
            begin
              xml_content = ''
              
              SystemTimer::timeout(10) do
                xml_content = open(url, 
                                  :proxy => HTTP_PROXY, 
                                  :http_basic_authentication => [ @username, @password ],
                                  'User-Agent' => 'SeekDa to BioCatalogue Importer').read
              end
              
              doc = XML::Parser.string(xml_content).parse
              
              service_nodes = doc.root.find('//result/service')
              
              if service_nodes.length == 0
                # Empty page
                has_items = false
              else
                query_services_count += service_nodes.length
                
                service_nodes.each do |service_node|
                  
                  stats["total_services_found_in_seekda"].increment
                  
                  seekda_id = service_node.attributes['id']
                  
                  wsdl_url_node = service_node.find_first('wsdl')
                  
                  if wsdl_url_node.nil? || (wsdl_url = wsdl_url_node.inner_xml).blank?
                    puts "ERROR: missing <wsdl> element for a search result."
                  else
                    
                    exclude_this = false
                    
                    @provider_excludes.each do |excluded_provider|
                      provider_node = service_node.find_first('provider')
                      if !provider_node.nil? && !(provider_url = provider_node.inner_xml).blank?
                        exclude_this = true if provider_url.match(excluded_provider)
                      end
                    end
                    
                    @wsdl_excludes.each do |excluded_wsdl|
                      exclude_this = true if wsdl_url.match(excluded_wsdl)
                    end
                    
                    if exclude_this
                      stats["total_services_excluded"].increment
                      puts ""
                      puts "> Excluding service with WSDL - #{wsdl_url}. (SeekDa ID: #{seekda_id})"
                    else
                      
                      puts ""
                      puts "> Processing service - #{wsdl_url}. (SeekDa ID: #{seekda_id})"
                      
                      # Normalize WSDL URL
                      wsdl_url = Addressable::URI.parse(wsdl_url).normalize.to_s
                      
                      soap_service = nil
                      service_ok = true
                
                      # Check if the service exists in the database and if not create it.
                      #
                      # NOTE: since we know that the duplication check for Soap Services currently 
                      # doesn't take into account the endpoint, we can just provide a blank string for that. 
                      if (existing_service = SoapService.check_duplicate(wsdl_url, "")).nil?
                        # Doesn't exist, so new SoapService needs to be created...
                        
                        soap_service = SoapService.new(:wsdl_location => wsdl_url)
                        new_service_success, data = soap_service.populate
                        
                        if new_service_success
                          new_service_success = soap_service.submit_service(data["endpoint"], @registry_source, { })
                          
                          if new_service_success
                            puts "INFO: new service (ID: #{soap_service.service(true).id}, WSDL URL: '#{wsdl_url}') successfully created!"
                            stats["ids_of_new_services"] << soap_service.service.id
                          else
                            puts "ERROR: failed to carry out submit_service of SoapService object with WSDL URL '#{wsdl_url}' (ie: db has not been populated with the SoapService and associated objects). Check the relevant Rails log file for more info."
                            service_ok = false
                          end
                        else
                          puts "ERROR: failed to populate SoapService object from WSDL URL '#{wsdl_url}'. Error messages: #{soap_service.errors.full_messages.to_sentence}"
                          service_ok = false
                        end
                      else
                        # Exists, so get the relevant SoapService object...
                        
                        puts "INFO: existing matching service found (ID: #{existing_service.id}, WSDL URL: '#{wsdl_url}')."
                        
                        unless stats["ids_of_new_services"].include?(existing_service.id) or stats["ids_of_existing_services"].include?(existing_service.id) 
                          stats["ids_of_existing_services"] << existing_service.id
                        end
                        
                        existing_service.service_versions.each do |s_v|
                          if (s_v.service_versionified_type == "SoapService") && ((s_v_i = s_v.service_versionified).wsdl_location.downcase == wsdl_url.downcase)
                            soap_service = s_v_i
                          end
                        end
                      end
                      
                      # Continue adding any annotations etc
                      if service_ok and !soap_service.nil?
                        # Store the query as a tag annotation
                        create_annotation(soap_service, "tag", query.gsub("tag:", ""), stats)
                        
                        service_deployment = soap_service.service_deployments.first
                        
                        # Store <availability> as a special annotation as well.
                        # This needs to be stored on the service depoyment.
                        availability_node = service_node.find_first('availability')
                        unless availability_node.nil? || (availability = availability_node.inner_xml).blank?
                          create_annotation(service_deployment, "SeekDa:availability", availability, stats)
                        end
                        
                        # SeekDa have a country code for each service. 
                        # Check this with ours and choose SeekDa over ours
                        # (since they use a commercial provider).
                        country_code_node = service_node.find_first('countryCode')
                        unless country_code_node.nil? || (country_code = country_code_node.inner_xml).blank?
                          country = CountryCodes.country(country_code)
                          
                          if service_deployment.country != country
                            previous_country = service_deployment.country
                            
                            service_deployment.country = country
                            service_deployment.city = ""
                            service_deployment.save
                            
                            puts "INFO: country for service deployment updated to '#{country}' (was '#{previous_country}')"
                          else
                            puts "INFO: countries match up. Woohoo!"
                          end
                        end
                      else
                        stats["total_services_failed_to_create"].increment
                      end
                      
                    end
                  end    
                end
                
                # If less than 10 services were found then it means that there won't be any more to get
                if service_nodes.length < 10
                  has_items = false
                else
                  # p=x in the SeekDa API actually means the item number, NOT page number.
                  current_start_item_index += 10
                end
                
              end
            rescue Exception => ex
              puts ""
              puts "> ERROR: failed to fetch or parse document from: #{url}. As a precaution, no more pages will be attempted for this query. Exception:"
              puts ex.message
              puts ex.backtrace.join("\n")
              
              has_items = false
            end
            
            sleep 2
            
          end
          
          puts ""
          puts "> #{query_services_count} services found for query: '#{query}'"
          
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
  
  protected
  
  def print_stats(stats)
    stats["ids_of_new_services"].sort!
    stats["ids_of_existing_services"].sort!
    
    stats["total_services_new"] = stats["ids_of_new_services"].length
    stats["total_services_existed"] = stats["ids_of_existing_services"].length
    
    puts ""
    puts ""
    puts "Stats:"
    puts "------"
    
    puts "Keywords used to search SeekDa (#{@keywords.length}) - #{@keywords.to_sentence}"
    puts "Tags used to search SeekDa (#{@tags.length}) - #{@tags.to_sentence}"
    
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
                         :source_type => "Registry",
                         :source_id => @registry_source.id,
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
puts "Redirecting output of $stdout to log file: seekda_import.log ..."
$stdout = File.new("seekda_import.log", "w")
$stdout.sync = true

# Redirect warnings from libxml-ruby
LibXML::XML::Error.set_handler do |error|
  #puts error.to_s
end

puts Benchmark.measure { SeekDaImporter.new(ARGV.clone).run }

# Reset $stdout
$stdout = STDOUT