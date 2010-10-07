#!/usr/bin/env ruby

# Generate a list of links found in descriptions and other annotations
# and check the status of the links
#
# NOTE : This is meant to only flag links that might need to be checked
#        by a human curator
#
#    -e, --environment=name           Specifies the environment to run this script under (test|development|production).
#                                     Default: development
#
#    -h, --help                       Show this help message.
#
# Depedencies:
# - Rails (v2.3.2)
#
# TODO : add documentation URLs to the list of links
# TODO : parse URLs before check
# TODO : Extend to Rest services. These are failing bec of a bug with the rest service models!

require 'optparse'
require 'benchmark'
require 'pp'

class LinksChecker
  
  attr_accessor :options
  
  def initialize(args)
    @options = {
      :environment => (ENV['RAILS_ENV'] || "production").dup,
    }
    
    args.options do |opts|
      opts.on("-e", "--environment=name", String,
              "Specifies the environment to run this script under (test|development|production).",
              "Default: development") { |v| @options[:environment] = v }
    
      opts.separator ""
    
      opts.on("-h", "--help", "Show this help message.") { puts opts; exit }
      
      opts.parse!
    end
  
    # Start the Rails app
    
    ENV["RAILS_ENV"] = @options[:environment]
    RAILS_ENV.replace(@options[:environment]) if defined?(RAILS_ENV)
    
    require File.join(File.dirname(__FILE__), '..', '..', 'config', 'environment')
  end  
  
  
    
  #puts "Redirecting output of $stdout to log file: '{RAILS_ROOT}/log/link_checker_{current_time}.log' ..."
  #$stdout = File.new(File.join(File.dirname(__FILE__), '..', '..', 'log', "links_checker_#{Time.now.strftime('%Y%m%d-%H%M')}.log"), "w")
  #$stdout.sync = true
  
  def run 
    all_links = []
    Service.all.each do |service|
      unless service.latest_version.service_versionified.is_a?(RestService)
        puts "Getting links in descriptions for service : #{service.name}"
        #pp self.check_all(links_for_service(service))
        all_links << links_for_service_h(service) unless links_for_service_h(service).empty?
      end
    end
    pp all_links
  end
  
  protected
  
  def service_annotatables(service)
    annotatables     = []
    service_instance = service.latest_version.service_versionified
    annotatables.concat(service.service_deployments)
    annotatables << service_instance
    if service_instance.respond_to?(:soap_operations)
      annotatables.concat(service_instance.soap_operations) 
      service_instance.soap_operations.each do |op|
        annotatables.concat(op.soap_inputs)
        annotatables.concat(op.soap_outputs)
      end
    end
    if service_instance.respond_to?(:rest_resources)
      annotatables.concat(service_instance.rest_resources) 
    end
    return annotatables
  end
  
  def non_provider_annotations(parent, attr='description')
    if parent.respond_to?(:annotations)
      return  parent.annotations.collect{|a| a.value if a.attribute.name.downcase == attr}.compact 
    end
    return []
  end
  
  def get_links_from_text(text)
    pieces = text.split
    pieces.collect!{ |p| p if p.match('http|www')}.compact
  end
  
  #TODO : parse the urls before running check
  def parse_link(link)
    
  end
  
  def links_for_annotatable(annotatable)
    links = []
    if annotatable.respond_to?(:description) 
      if annotatable.description
        links.concat(self.get_links_from_text(annotatable.description))
      end
      self.non_provider_annotations(annotatable).each do |ann|
        links.concat(self.get_links_from_text(ann))  
      end
    end
    return links
  end
  
  def links_for_annotatable_h(annotatable)
    links = {}
    unless self.links_for_annotatable(annotatable).empty?
      links[annotatable.class.name+(annotatable.id.to_s)] = self.links_for_annotatable(annotatable)
    end
    return links
  end
  
  def links_for_service(service)
    links   = []
    self.service_annotatables(service).each  do |ann|
      links.concat(self.links_for_annotatable(ann))
    end
    return links
  end
  
  # Returns a hash of services and the links of links
  # found in the service components like soap
  # operations and inputs & outputs.
  # Has structure:
  #  { service_name+id => [ { component_class+id => [ list of urls]},
  #                          { component_class+id => [ list of urls]} ]}
  #
  # Example:
  #     {"WSDBFetchServerService2701"=>
  #                [{"SoapOperation19687"=>
  #                       ["http://www.ebi.ac.uk/Tools/webservices/services/dbfetch#fetchbatch_db_ids_format_style)."]},
  #                 {"SoapOperation19686"=>
  #                       ["http://www.ebi.ac.uk/Tools/webservices/services/dbfetch#fetchdata_query_format_style)."]},
  #                 {"SoapOperation19685"=>
  #                       ["http://www.ebi.ac.uk/Tools/webservices/services/dbfetch#getdbformats_db)."]},
  #                 {"SoapOperation19690"=>
  #                       ["http://www.ebi.ac.uk/Tools/webservices/services/dbfetch#getformatstyles_db_format)."]},
  #                 {"SoapOperation19688"=>
  #                       ["http://www.ebi.ac.uk/Tools/webservices/services/dbfetch#getsupporteddbs)."]},
  #                 {"SoapOperation19689"=>
  #                       ["http://www.ebi.ac.uk/Tools/webservices/services/dbfetch#getsupportedformats)."]},
  #                 {"SoapOperation19691"=>
  #                       ["http://www.ebi.ac.uk/Tools/webservices/services/dbfetch#fetchdata_query_format_style)."]}
  #                 ]
  #       }
  # 
  #
  
  def links_for_service_h(service)
    links   = []
    s_links = {}
    self.service_annotatables(service).each do |ann|
      unless links_for_annotatable_h(ann).empty?
        links << links_for_annotatable_h(ann)
      end
    end
    s_links[service.name+(service.id.to_s)] = links unless links.empty?
    return s_links
  end
  
  #check the accessibility of a url. Follows up to 3 redirects
  def accessible?(url)
    return BioCatalogue::AvailabilityCheck::URLCheck.new(url).available?
  end
  
  def check_all(links=[])
    checked = {}
    links.each do |link|
      checked[link] = self.accessible?(link)
    end
    return checked
  end
  
end

LinksChecker.new(ARGV.clone).run

