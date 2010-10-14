#!/usr/bin/env ruby
#
# This script generate a list of links found in descriptions and other annotations
# and checks the status of the links . It then produces an html file with a table of links which
# might no longer be accessible. It is expected that a human would follow up on
# the flags raised by this script. The html file generated is place in the /public folder 
# 
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
  
  
  def run 
    @all_links           = []
    @all_data_with_links = []
    Service.all.each do |service|
      puts "Searching link for service : #{service.name}"
      @all_links.concat(links_for_service(service))
      @all_data_with_links << links_for_service_h(service) unless links_for_service_h(service).empty?
    end
    @checked_links = self.check_all(@all_links.uniq)
    self.report(@all_data_with_links, @checked_links )
  end
  
  protected
  
  def report(all_data_with_links, all_links_with_status)
    puts "Redirecting output of $stdout to log file: '{RAILS_ROOT}/public/link_checker_{current_time}.html' ..."
    $stdout = File.new(File.join(File.dirname(__FILE__), '..', '..', 'public', "links_checker_#{Time.now.strftime('%Y%m%d-%H%M')}.html"), "w")
    $stdout.sync = true
    puts '<html>'
    
    puts "<h3> List of links that need curator attention : Generated on #{Time.now.strftime("%A %B %d , %Y")}</h3>"
    puts "<hr/>"
    
    puts '<table border=2>'
    puts '<th> Service Name </th>'
    puts '<th> Component Name </th>'
    puts '<th> Link </th>'
    puts '<th> Link Status </th>'
    
    count =0
    all_data_with_links.each do |service_item|
      bg = "#ffbb2A"
      if count % 2 == 0
        bg = "#aabbcc"
      end
      self.report_for_service(service_item, all_links_with_status , bg)
      count = count + 1
    end
    
    puts '</table>'
    puts '</html>'
    $stdout = STDOUT
  end
  
  def report_for_service(service_item,  all_links_with_status, bg="#aabbcc")
    service_item.each do |name, component_links| # service_item is a hash
      component_links.each do |cl| # each cl is a hash
        cl.each do |cname, links|
          links.each do |link|
            if all_links_with_status[link] == false
              puts "<tr bgcolor='#{bg}'>"
              puts "<td><a href='#{SITE_BASE_HOST}/services/#{name.split('_')[1]}' target='_blank'> #{name}</a></td> " 
              puts "<td><a href='#{SITE_BASE_HOST}/#{cname.split('_')[0].underscore.pluralize}/#{cname.split('_')[1]}' target='_blank'> #{cname}</a></td> " 
              puts "<td><a href='#{link}' target='_blank'>#{link}</a> </td>  "     
              puts "<td>#{all_links_with_status[link]} </td>"    
              puts '</tr>'
            end
          end
        end
      end
    end
  end
    
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
    pieces.collect!{ |p| self.parse_link(p) if p.match('http|www')}.compact
  end
  
  # This is attempt to put links into format.
  # It is anecdotal as it is designed looking at the
  # the data. May not work for all links
  def parse_link(link)
    return nil if link.nil?
    while link.match('^\(|^\[')  # remove leading '(', '[' 
      link = link[1, (link.size-1)]
    end
    while link.match('\)$|\.$|\\$')
      link = link[0, (link.size-1)]
    end
    if link.match('^www')
      link = 'http://' + link
    end
    
    if link.match("^href|^HREF")
      pieces = link.split('"')
      pieces = link.split("'") if pieces.size == 1
      link = pieces.collect!{ |p| p if p.match('http|www')}.compact.first
    end
    return link
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
      if annotatable.is_a?(SoapService) || annotatable.is_a?(RestService)
        self.non_provider_annotations(annotatable, 'documentation_url').each do |ann|
          links.concat(self.get_links_from_text(ann))  
        end
      end
    end
    #puts "Found #{links.count} links for #{annotatable.class.name + annotatable.id.to_s}"
    #pp links
    return links
  end
  
  def links_for_annotatable_h(annotatable)
    links = {}
    unless self.links_for_annotatable(annotatable).empty?
      links[annotatable.class.name+'_'+(annotatable.id.to_s)] = self.links_for_annotatable(annotatable)
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
  
  # Returns a hash of services and the list of links
  # found in the description of service components like soap
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
    s_links[service.name+'_'+(service.id.to_s)] = links unless links.empty?
    return s_links
  end
  
  #check the accessibility of a url. Follows up to 3 redirects
  def accessible?(url)
    return BioCatalogue::AvailabilityCheck::URLCheck.new(url).available?
  end
  
  def check_all(links=[])
    checked = {}
    links.each do |link|
      checked[link] = false
      #checked[link] = self.accessible?(link)
    end
    return checked
  end
  
end

LinksChecker.new(ARGV.clone).run

