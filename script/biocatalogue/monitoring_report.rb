#!/usr/bin/env ruby

# This script generate a reports about service statuses. It currently generates a
# list of link to failing tests. 
#
# NOTE : This script is intended for debugging purposes only
#
# Usage: monitoring_report [options]
#
#    -e, --environment=name           Specifies the environment to run this script under (test|development|production).
#                                     Default: development
#
#    -h, --help                       Show this help message.
#
# Depedencies:
# - Rails (v2.3.2)

require 'optparse'
require 'benchmark'




class MonitoringReport
  
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
    stats = {
      :all => { :passed => [], :failed => [], :unchecked => [] },
      :availability_checks => { :passed => [], :failed => [] },
      :test_scripts => { :passed => [], :failed => [] } 
    }
    
    failed_st_stats = []
    
    Service.all.each do |service|
      unless service.archived?
        case service.latest_status.label
          when "PASSED"
            stats[:all][:passed] << service.id
          when "UNCHECKED"
            stats[:all][:unchecked] << service.id
          else
            stats[:all][:failed] << service.id
            service.service_tests.each do |st|
              if st.latest_status.label =='FAILED' || st.latest_status.label =='WARNING'
                failed_st_stats << {:service_id => service.id, :test_type => st.test_type, 
                                    :st_action => st.test.property, :failing_since => st.failing_since} if st.test_type =='UrlMonitor'
                failed_st_stats << {:service_id => service.id, :test_type => st.test_type, 
                                    :st_action => st.test.exec_name, :failing_since => st.failing_since} if st.test_type =='TestScript'
              end
            end
          end

	
        # FIXME: the logic below is a bit hacky and duplicated. Need to DRY this out!
      
        u_status = nil
        u_tests = service.service_tests_by_type("UrlMonitor")
        u_tests.each do |t|
          u_status = 0 if u_status.nil?
	  x = t.latest_test_result.result
	  if x >= 0
            u_status += x
	  end
        end
	unless u_status.nil?
          if u_status == 0
            stats[:availability_checks][:passed] << service.id
          else
            stats[:availability_checks][:failed] << service.id
          end
	end
        
        t_status = nil
        t_tests = service.service_tests_by_type("TestScript")
        t_tests.each do |t|
          t_status = 0 if t_status.nil?
	  x = t.latest_test_result.result
	  if x >= 0
            t_status += x
	  end
        end
	unless t_status.nil?
          if t_status == 0
            stats[:test_scripts][:passed] << service.id
          else
            stats[:test_scripts][:failed] << service.id
          end
	end

      end

    end
    
    puts "Redirecting output of $stdout to log file: '{RAILS_ROOT}/log/monitoring_report_{current_time}.html' ..."
    $stdout = File.new(File.join(File.dirname(__FILE__), '..', '..', 'log', "monitoring_report_#{Time.now.strftime('%Y%m%d-%H%M')}.html"), "w")
    $stdout.sync = true
    
    puts "<html>"
    puts "<h3> Failing Services List Generated on #{Time.now.strftime("%A %B %d , %Y")}</h3>"
    puts "<hr/>"
    
    puts "<p>"
    puts " Total number of non archived services: #{Service.count(:conditions => { :archived_at => nil })}"
    puts "</p>"

    puts "<h4>ALL service tests</h4>"
    puts "<p>"
    puts "No of passed services: #{stats[:all][:passed].count} <br/>"
    puts "No of failed services: #{stats[:all][:failed].count} <br/>"
    puts "No of unchecked services: #{stats[:all][:unchecked].count} <br/>"
    puts "<br/>"
    puts "No of failed service tests: #{failed_st_stats.count}"
    puts "</p>"
    puts "<br/>"
    
    puts "<h4>Availability service tests</h4>"
    puts "<p>"
    puts "No of passed services: #{stats[:availability_checks][:passed].count} <br/>"
    puts "No of failed services: #{stats[:availability_checks][:failed].count} <br/>"
    puts "</p>"
    puts "<br/>"

    puts "<h4>Test script service tests</h4>"
    puts "<p>"
    puts "No of passed services: #{stats[:test_scripts][:passed].count} <br/>"
    puts "No of failed services: #{stats[:test_scripts][:failed].count} <br/>"
    puts "</p>"
    puts "<br/>"

    failed_st_stats.sort!{|a, b| a[:failing_since] <=> b[:failing_since]} # sort by failing since
    service_ids = failed_st_stats.collect{|fts| fts[:service_id]}.compact.uniq
    
    puts '<table border=2>'
    puts '<th> Service URL</th>'
    puts '<th> Failing Tests</th>'
    
    
    service_ids.each do |failed|
      puts "<tr>"
      puts "<td>"
      puts "<a href='#{SITE_BASE_HOST}/services/#{failed}'> #{SITE_BASE_HOST}/services/#{failed}</a> <br/>"
      puts "</td>"
      puts "<td>"
      failed_st_stats.collect{|st| st if st[:service_id] == failed }.compact.each do |fst|
        puts "#{fst[:test_type]} : #{fst[:st_action]}  <br/> "
        puts "Failing Since : #{fst[:failing_since].strftime("%A %B %d , %Y")} <br/>"
      end
      puts "</td>"
      puts "</tr>"
    end
    puts "</table>"
    puts "</p>"
    puts "</html>"
    
    # Reset $stdout
    $stdout = STDOUT
  end
end


puts Benchmark.measure {
  MonitoringReport.new(ARGV.clone).run
}

