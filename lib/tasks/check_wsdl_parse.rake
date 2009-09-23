# BioCatalogue: lib/tasks/check_wsdl_parse.rake
#
# Copyright (c) 2009, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details


namespace :biocatalogue do
  namespace :wsdl_parser do
    desc "check all the soap service wsdls parse"
    task :check_all => :environment do
      info = check(Service.find(:all))
      write_report(info)
    end
    
    desc "check last 50 soap service wsdls parse"
    task :check_last_50 => :environment do
      info = check(Service.find(:all).last(50))
      write_report(info)
    end
    
    desc "check first 50 soap service wsdls parse"
    task :check_first_50 => :environment do
      info = check(Service.find(:all).first(50))
      write_report(info)
    end
    
    
    desc "check first 10 soap service wsdls parse"
    task :check_first_10 => :environment do
      info = check(Service.find(:all).first(10))
      write_report(info)
    end
    
    desc "check last 10 soap service wsdls parse"
    task :check_last_10 => :environment do
      info = check(Service.find(:all).last(10))
      write_report(info)
    end
    
    # use BioCatalogue wsdl parser to check
    # if registered wsdl still parse.
    # Can also be used to reveal dead wood...
    def check(services)
      count  = 1
      failed = [] 
      services.each do |service|
        service.service_version_instances_by_type('soap').each do |soap|
          begin
            info, error, data = BioCatalogue::WSDLUtils::WSDLParser.parse(soap.wsdl_location)
            if info.empty?
              raise "wsdl info hash is empty! "
            end
            puts "#{count} WSDL parse OK"
          rescue
            failed << soap.wsdl_location
            puts "#{count} WSDL parse FAILED"
            #puts "ERROR  : #{soap.wsdl_location}"
          end
          count +=1
        end
      end
      return [ count, failed ]
    end
    
    # write summary report of the parsing
    def  write_report(details)
      count, failed = details
      
      log = 'tmp/pids/wsdl_parse_check.log'
      $stdout.reopen(log, "w")
      $stdout.sync = true
      $stderr.reopen $stdout
      puts "Start Time : #{Time.now}"
      
      puts "Summary Report"
      puts "================"
      puts "No of wsdls processed         : #{count}"
      puts "No of wsdls with parse OK     : #{count - failed.length}"
      puts "No of wsdls with parse FAILED : #{failed.length}"
      unless failed.empty?
        puts "WSDLs that failed to parse"
        failed.each  do |wsdl|
          puts wsdl
        end
      end

      puts "End Time : #{Time.now}"
      $stdout = STDOUT
      $stderr = STDERR
    end
    
  end
end