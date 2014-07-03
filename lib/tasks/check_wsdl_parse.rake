# BioCatalogue: lib/tasks/check_wsdl_parse.rake
#
# Copyright (c) 2009, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details


namespace :biocatalogue do
  namespace :wsdl_parser do

    desc "Compare the new WSDL parsing utility based on Taverna's wsdl-generic with the old PHP WSDLUtils."
    task :compare_wsdl_parsers => :environment do

      wsdl_parsing_comparison_report_folder = Rails.root.join('data',"wsdl_parsing_comparison_reports-#{Rails.env}")
      unless Dir.exists?(wsdl_parsing_comparison_report_folder)
        Dir.mkdir(wsdl_parsing_comparison_report_folder)
      end

      time = Time.now.strftime("%Y%m%d%H%M")
      report_file = "#{wsdl_parsing_comparison_report_folder}/comparison_report-#{time}.txt"

      # Get all SOAP services
      soap_services = SoapService.where(:id => 1..10) #all

      comparison_result = ''
      problematic_services = []

      soap_services.each do |soap_service|
        if (!soap_service.service.archived?)

          wsdl_url = soap_service.wsdl_location
          comparison_result += "\n\n*****************************************************************\nService id: #{soap_service.service.id}; WSDL: #{wsdl_url}.\n"

          # Check is WSDL doc is reachable at all
          begin
            timeout(10.seconds) do
              open(wsdl_url.strip(), :proxy => HTTP_PROXY, "User-Agent" => HTTP_USER_AGENT).read
            end
          rescue Exception => ex
            comparison_result += "WSDL document does not seem to be reachable - skipping parsing.\n"
            problematic_services << {:id => soap_service.service.id, :wsdl => wsdl_url}
            next
          end

          begin
            service_info, error_messages = BioCatalogue::WsdlParser.parse_via_tavernas_wsdl_generic(wsdl_url)
            service_info_old, error_messages_old = BioCatalogue::WsdlParser.parse(wsdl_url)

            if !service_info.blank?
              if !service_info_old.blank?
                # Both parsers managed to parse the WSDL - compare the resulting hashes

                problem = false

                if service_info['name'] != service_info_old['name']
                  comparison_result << "Name differs. New: #{service_info['name']}. Old: #{service_info_old['name']}.\n"
                  problem = true
                end
                if service_info['description'] != service_info_old['description']
                  comparison_result << "Description differs. New: #{service_info['description']}. Old: #{service_info_old['description']}.\n"
                  problem = true
                end
                if service_info['namespace'] != service_info_old['namespace']
                  comparison_result << "Namespace differs. New: #{service_info['namespace']}. Old: #{service_info_old['namespace']}.\n"
                  problem = true
                end
                if service_info['ports'].count != service_info_old['ports'].count
                  comparison_result << "Number of ports differ. New: #{service_info['ports'].count}. Old: #{service_info_old['ports'].count}.\n"
                  problem = true
                end
                if service_info['operations'].count != service_info_old['operations'].count
                  comparison_result << "Number of operations differ. New: #{service_info['operations'].count}. Old: #{service_info_old['operations'].count}.\n"
                  problem = true
                end

                problematic_services << {:id => soap_service.service.id, :wsdl => wsdl_url} if problem
              else
                comparison_result << "New parser parsed. Old parser failed to parse with the following errors: #{error_messages_old}.\n"
                problematic_services << {:id => soap_service.service.id, :wsdl => wsdl_url}
              end
            else
              if !service_info_old.blank?
                comparison_result << "New parser failed to parse with the following errors: #{error_messages}. Old parser parsed.\n"
                problematic_services << {:id => soap_service.service.id, :wsdl => wsdl_url}
              else
                comparison_result << "Both parsers failed to parse. New parser errors: #{error_messages}. Old parser errors: #{error_messages_old}.\n"
                problematic_services << {:id => soap_service.service.id, :wsdl => wsdl_url}
              end
            end
          rescue Exception => ex
            comparison_result << "Parsing WSDL of SOAP service with id #{soap_service.service.id} caused exception: #{ex.message}.\n"
            problematic_services << {:id => soap_service.service.id, :wsdl => wsdl_url}
          end
        end
      end

      comparison_result = "Number of services that need looking into: #{problematic_services.count}.\n#{problematic_services}\n" + comparison_result if problematic_services.count > 0
      File.open(report_file, 'w+') { |file| file.write(comparison_result) }
      Rails.logger.info('WSDL aprsing comparison report written to' + report_file)
    end

    desc "check soap service wsdls parse"
    task :check => :environment do
      
      last_no  = ENV['last']
      first_no = ENV['first']
      all      = ENV['all']
      services = []
      if last_no.to_i > 0 then
        services.concat(Service.all.last(last_no.to_i))
      end
      if first_no.to_i > 0
        services.concat(Service.all.last(first_no.to_i))
      end
      
      if all
        services = Service.all
      end
      if (!last_no && !first_no && !all)
        puts "You need to pass configuation parameters. For example, to check the first 3 services in development do :"
        puts "rake biocatalogue:wsdl_parser:check RAILS_ENV=development first=3"
        exit(0)
      end
      info = check(services)
      write_report(info)
    end
    
    # use BioCatalogue wsdl parser to check
    # if registered wsdl still parse.
    # Can also be used to reveal dead wood...
    def check(services)
      count  = 1
      failed = [] 
      services.each do |service|
        service.service_version_instances_by_type('SoapService').each do |soap|
          begin
            info, error, data = BioCatalogue::WsdlUtils::ParserClient.parse(soap.wsdl_location)
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

    def test_tavernas_wsdl_generic_parser(wsdl_url)
      #wsdl_url = '/Users/alex/git/taverna-wsdl-generic/src/test/resources/testwsdls/menagerie-complex-rpc.wsdl'
      puts "Parsing #{wsdl_url}."
      #service_info, error_messages, wsdl_doc_content = BioCatalogue::WsdlParser.parse_via_tavernas_wsdl_generic(wsdl_url)

      taverna_wsdl_parser_class = Rjb::import('net.sf.taverna.wsdl.parser.WSDLParser')
      parsed_wsdl = taverna_wsdl_parser_class.new(wsdl_url)
      operations = parsed_wsdl.getOperations()

      service_info = {}
      service_info['operations'] = []

      i = 0
      while i < operations.size() do
        op = operations.get(i)

        operation = {}
        operation['name'] = op.getName()
        operation['description'] = parsed_wsdl.getOperationDocumentation(op.getName())
        endpoint_locations = parsed_wsdl.getOperationEndpointLocations(op.getName())
        operation['action'] = endpoint_locations.isEmpty() ? '' : endpoint_locations.get(0)
        operation['operation_type'] = '' #?
        operation['parameter_order'] = parsed_wsdl.getParameterOrder(op)
        operation['parent_port_type'] = parsed_wsdl.getPortForOperation(op.getName()).getName() # the name of the port (not portType!) element that contains the binding that this operation belongs to
        operation['inputs'] = []
        operation['outputs'] = []

        # Build hashes for inputs and outputs of this operation
        inputs = parsed_wsdl.getOperationInputParameters(op.getName())
        j = 0
        while j < inputs.size() do
          input = inputs.get(j)
          inp = {}
          inp['name'] = input.getName()
          inp['description'] = input.getDocumentation()
          inp['computational_type'] = input.getType()
          inp['computational_type_details'] = BioCatalogue::WsdlParser.build_message_type_details(input)
          operation['inputs'] << inp
          j += 1
        end
        service_info['operations'] << operation
      end
      puts service_info
    end
  end
end