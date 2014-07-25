# BioCatalogue: lib/tasks/check_wsdl_parse.rake
#
# Copyright (c) 2009, University of Manchester, The European Bioinformatics
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details


namespace :biocatalogue do
  namespace :wsdl_parser do

    # A simple task that parses the WSDL URL (based on Taverna's wsdl-generic parser) passed as command line argument as rake biocatalogue:wsdl_parser:parse wsdl='http://blah.com?wsdl'
    desc "Parse WSDL document using the new WSDL parsing utility based on Taverna's wsdl-generic. Pass WSDL URL as rake biocatalogue:wsdl_parser:parse_wsdlgeneric wsdl='http://blah.com?wsdl'"
    task :parse_wsdlgeneric => :environment do
      wsdl_url = ENV['wsdl']
      puts("Parsing WSDL doc: #{wsdl_url} using Taverna's wsdl-generic.")
      if wsdl_url.blank?
        puts('You have to specify WSDL URL as e.g. rake biocatalogue:wsdl_parser:parse_wsdlgeneric wsdl=http://blah.com?wsdl')
      else
        # Check is WSDL doc is reachable at all
        begin
          timeout(10.seconds) do
            open(wsdl_url.strip(), :proxy => HTTP_PROXY, "User-Agent" => HTTP_USER_AGENT).read
          end
        rescue Exception => ex
          puts('WSDL document does not seem to be reachable - skipping parsing.')
          exit(-1)
        end

        begin
          service_info, error_messages = BioCatalogue::WsdlParser.parse_via_tavernas_wsdl_generic(wsdl_url)

          if !service_info.blank?
            puts("Successfully parsed - see the resulting hash below: \n #{service_info}")
          else
            puts("Parser failed to parse with the following errors: #{error_messages}.")
          end
        rescue Exception => ex
          stacktrace = ex.backtrace.join("\n")
          puts("Parsing caused exception: #{ex.message}. Stacktrace: #{stacktrace}\n")
        end
      end
    end

    # A simple task that parses the WSDL URL (based on the old PHP WSDLUtils parser) passed as command line argument as rake biocatalogue:wsdl_parser:parse_old wsdl='http://blah.com?wsdl'
    desc "Parse WSDL document using the old PHP WSDL parsing utility WSDLUtils. Pass WSDL URL as rake biocatalogue:wsdl_parser:parse_wsdlutils wsdl='http://blah.com?wsdl'"
    task :parse_wsdlutils => :environment do
      wsdl_url = ENV['wsdl']
      puts("Parsing WSDL doc: #{wsdl_url} using WSDLUtils.")
      if wsdl_url.blank?
        puts('You have to specify WSDL URL as e.g. rake biocatalogue:wsdl_parser:parse_wsdlutils wsdl=http://blah.com?wsdl')
      else
        # Check is WSDL doc is reachable at all
        begin
          timeout(10.seconds) do
            open(wsdl_url.strip(), :proxy => HTTP_PROXY, "User-Agent" => HTTP_USER_AGENT).read
          end
        rescue Exception => ex
          puts('WSDL document does not seem to be reachable - skipping parsing.')
          exit(-1)
        end

        begin
          service_info, error_messages = BioCatalogue::WsdlParser.parse_via_wsdlutils(wsdl_url)

          if !service_info.blank?
            puts("Successfully parsed - see the resulting hash below: \n #{service_info}")
          else
            puts("Parser failed to parse with the following errors: #{error_messages}.")
          end
        rescue Exception => ex
          stacktrace = ex.backtrace.join("\n")
          puts("Parsing caused exception: #{ex.message}. Stacktrace: #{stacktrace}\n")
        end
      end
    end

    desc "Compare the new WSDL parsing utility based on Taverna's wsdl-generic with the old PHP WSDLUtils."
    task :compare_wsdl_parsers => :environment do
      wsdl_parsing_comparison_report_folder = Rails.root.join('data',"wsdl_parsing_comparison_reports-#{Rails.env}")
      unless Dir.exists?(wsdl_parsing_comparison_report_folder)
        Dir.mkdir(wsdl_parsing_comparison_report_folder)
      end

      time = Time.now.strftime("%Y%m%d%H%M")
      report_file = "#{wsdl_parsing_comparison_report_folder}/comparison_report-#{time}.txt"

      my_logger ||= Logger.new(report_file)
      puts("Logging to file #{report_file}")

      # Get all SOAP services
      soap_services = SoapService.all #where(:id => 1..20)

      problematic_services = []
      different_parsing_results_services = []
      both_parsers_failed_services = []
      new_parser_failed_old_worked_services = []
      unreachable_services = []

      soap_services.each do |soap_service|
        my_logger.info("\n*****************************************************************\n")
        my_logger.info("Processing SOAP service id: #{soap_service.id}; parent service id: #{soap_service.service.id}; WSDL: #{soap_service.wsdl_location}.\n")
        puts("Processing SOAP service id: #{soap_service.id}; parent service id: #{soap_service.service.id}; WSDL: #{soap_service.wsdl_location}.\n")

        if (soap_service.service.archived?)
          my_logger.info("Service archived - skipping.\n")
        elsif
        wsdl_url = soap_service.wsdl_location

          # Check is WSDL doc is reachable at all
          begin
            timeout(10.seconds) do
              open(wsdl_url.strip(), :proxy => HTTP_PROXY, "User-Agent" => HTTP_USER_AGENT).read
            end
          rescue Exception => ex
            my_logger.info("WSDL document does not seem to be reachable - skipping parsing.\n")
            unreachable_services << {:id => soap_service.service.id, :soap_service_id => soap_service.id, :wsdl => wsdl_url}
            next
          end

          begin
            service_info, error_messages = BioCatalogue::WsdlParser.parse_via_tavernas_wsdl_generic(wsdl_url)
            service_info_old, error_messages_old = BioCatalogue::WsdlParser.parse_via_wsdlutils(wsdl_url)

            if !service_info.blank?
              if !service_info_old.blank?
                # Both parsers managed to parse the WSDL - compare the resulting hashes

                problem = false
                if service_info['name'] != service_info_old['name']
                  # They may differ but one may be nil and the other one '' - in this case we treat them as if they are the same
                  if !(service_info['name'].blank? && service_info_old['name'].blank?)
                    my_logger.info("Name differs. New: #{service_info['name']}\n Old: #{service_info_old['name']}\n")
                    problem = true
                  end
                end
                if service_info['description'] != service_info_old['description']
                  if !(service_info['description'].blank? && service_info_old['description'].blank?)
                    my_logger.info("Description differs. New: #{service_info['description']}\n Old: #{service_info_old['description']}\n")
                    problem = true
                  end
                end
                if service_info['namespace'] != service_info_old['namespace']
                  if !(service_info['namespace'].blank? && service_info_old['namespace'].blank?)
                    my_logger.info("Namespace differs. New: #{service_info['namespace']}\n Old: #{service_info_old['namespace']}\n")
                    problem = true
                  end
                end
                if service_info['ports'].count != service_info_old['ports'].count
                  if !(service_info['ports'].blank? && service_info_old['ports'].blank?)
                    my_logger.info("Number of ports differ. New: #{service_info['ports'].count}\n Old: #{service_info_old['ports'].count}\n")
                    problem = true
                  end
                end
                if service_info['operations'].count != service_info_old['operations'].count
                  if !(service_info['operations'].blank? && service_info_old['operations'].blank?)
                    my_logger.info("Number of operations differ. New: #{service_info['operations'].count}\n Old: #{service_info_old['operations'].count}\n")
                    problem = true
                  end
                end

                if problem
                  different_parsing_results_services << {:id => soap_service.service.id, :soap_service_id => soap_service.id, :wsdl => wsdl_url}
                else
                  my_logger.info("Both parsers parsed and produced the same results.\n")
                end
              else
                my_logger.info("New parser parsed. Old parser failed to parse with the following errors: #{error_messages_old}.\n")
              end
            else
              if !service_info_old.blank?
                my_logger.info("New parser failed to parse with the following errors: #{error_messages}. Old parser parsed.\n")
                new_parser_failed_old_worked_services << {:id => soap_service.service.id, :soap_service_id => soap_service.id, :wsdl => wsdl_url}
              else
                my_logger.info("Both parsers failed to parse. New parser errors: #{error_messages}. Old parser errors: #{error_messages_old}.\n")
                both_parsers_failed_services << {:id => soap_service.service.id, :soap_service_id => soap_service.id, :wsdl => wsdl_url}
              end
            end
          rescue Exception => ex
            stacktrace = ex.backtrace.join("\n")
            my_logger.info("Parsing WSDL of SOAP service with id #{soap_service.service.id} caused exception: #{ex.message}. Stacktrace: #{stacktrace}.\n")
            problematic_services << {:id => soap_service.service.id, :soap_service_id => soap_service.id, :wsdl => wsdl_url}
          end
        end
      end

      my_logger.info("\n*****************************************************************\n")
      my_logger.info("Comparison report results:\n")
      my_logger.info("Number of services that need looking into: #{different_parsing_results_services.count + both_parsers_failed_services.count + new_parser_failed_old_worked_services.count}.\n")
      my_logger.info("Different parsing results for services: #{different_parsing_results_services}\n\n") if different_parsing_results_services.count > 0
      my_logger.info("New parser failed, old parser worked for services: #{new_parser_failed_old_worked_services}\n\n") if new_parser_failed_old_worked_services.count > 0
      my_logger.info("Both parsers failed for services: #{both_parsers_failed_services}\n\n") if both_parsers_failed_services.count > 0
      my_logger.info("Number of services with unreachable WSDL documents: #{unreachable_services.count}.\n#{unreachable_services}\n") if unreachable_services.count > 0
      puts('WSDL parsing comparison report written to ' + report_file)
    end

    desc "Update SOAP services using the new WSDL parsing utility based on Taverna's wsdl-generic."
    task :update_soap_services => :environment do
      # Get all SOAP services, archived or not
      soap_services = SoapService.all #where(:id =>3020 .. 3020)#where(:id => 3362..3362)

      soap_service_update_report_folder = Rails.root.join('data',"soap_service_update_reports-#{Rails.env}")
      unless Dir.exists?(soap_service_update_report_folder)
        Dir.mkdir(soap_service_update_report_folder)
      end

      time = Time.now.strftime("%Y%m%d%H%M")
      report_file = "#{soap_service_update_report_folder}/soap_service_update_report-#{time}.txt"

      my_logger ||= Logger.new(report_file)
      puts("Logging to file #{report_file}")

      my_logger.info("************ SOAP services update report *************\n\n")

      soap_services.each do |soap_service|
        wsdl_url = soap_service.wsdl_location

        puts("Updating SOAP service #{soap_service.id} with parent id #{soap_service.service.id}.\n")
        my_logger.info("Updating SOAP service #{soap_service.id} with parent id #{soap_service.service.id}.\n")

        # Check is WSDL doc is reachable at all
        begin
          timeout(10.seconds) do
            open(wsdl_url.strip(), :proxy => HTTP_PROXY, "User-Agent" => HTTP_USER_AGENT).read
          end
        rescue Exception => ex
          my_logger.info("WSDL document does not seem to be reachable - skipping this service.\n")
          next
        end

        begin
          service_info, error_messages, wsdl_file_contents = BioCatalogue::WsdlParser::parse(wsdl_url)

          if !service_info.blank?

            c_blob = ContentBlob.create(:data => wsdl_file_contents)
            soap_service.wsdl_files << WsdlFile.new(:location => wsdl_url, :content_blob_id => c_blob.id)
            soap_service.name  = service_info['name']
            soap_service.description  = service_info['description']

            soap_service.soap_service_ports.each do |port|
              port.destroy
            end
            soap_service.soap_operations.each do |soap_operation|
              soap_operation.destroy
            end
            soap_service.build_soap_service_ports(service_info, soap_service.build_soap_objects(service_info))
            soap_service.save!

          else
            my_logger.info("Failed to parse this service's WSDL - skipping this service. Errors: #{error_messages}.\n")
          end
        rescue Exception => ex
          stacktrace = ex.backtrace.join("\n")
          my_logger.info("Parsing WSDL of SOAP service with id #{soap_service.id} and parent id #{soap_service.service.id} caused exception: #{ex.message}. Stacktrace: #{stacktrace}\n")
        end
      end

      puts('SOAP services update report written to ' + report_file)
    end

    desc "Check SOAP service WSDLs parse - using PHP WSDLUtils parser."
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

    # Use WSDLUtils WSDL parser to check
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


    def hash_diff(one, other)
      (one.keys + other.keys).uniq.inject({}) do |memo, key|
        unless one.key?(key) && other.key?(key) && one[key] == other[key]
          memo[key] = [one.key?(key) ? one[key] : :_no_key, other.key?(key) ? other[key] : :_no_key]
        end
        memo
      end
    end
  end
end