# BioCatalogue: lib/bio_catalogue/monitoring.rb
#
# Copyright (c) 2009, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

module BioCatalogue
  module Monitoring
    
    INTERNAL_TEST_TYPES = [ 'TestScript', 'UrlMonitor' ].freeze
    
    class MonitorUpdate
    
      def self.run
        Service.find(:all).each do |service|
        # get all service deploments
        deployments = service.service_deployments
    
        #register the endpoints for monitoring
        update_deployment_monitors(deployments)
    
        #get all service instances(soap & rest)
        instances = service.service_version_instances
    
        soap_services = instances.delete_if{ |instance| instance.class.to_s != "SoapService" }
        update_soap_service_monitors(soap_services)
        end
      end
  
  
      protected 

      # from a list service deployments, check if
      # the endpoints are being monitored already.
      # If not, add the endpoint to the list of endpoints to
      # to monitor

      def self.update_deployment_monitors(deployments)
  
        deployments.each do |dep|
          monitor = UrlMonitor.find(:first , :conditions => ["parent_id= ? AND parent_type= ?", dep.id, dep.class.to_s ])
          if monitor.nil?
              mon = UrlMonitor.new(:parent_id => dep.id, 
                              :parent_type => dep.class.to_s, 
                              :property => "endpoint")
              service_test = ServiceTest.new( :service_id => dep.service.id,
                                              :test_type => mon.class.name, :activated_at => Time.now )
              mon.service_test = service_test                         
              if mon.save!
                puts "Created new monitor for deployment id : #{dep.id}"
              end
          end
        end
      end

      # from a list of endpoints soap services
      # add the wsdl locations to the list of url to monitor
      # if these are not being monitored already

      def self.update_soap_service_monitors(soap_services)
  
        soap_services.each do |ss|
          monitor = UrlMonitor.find(:first , :conditions => ["parent_id= ? AND parent_type= ?", ss.id, ss.class.to_s ])
          if monitor.nil?
              mon = UrlMonitor.new(:parent_id => ss.id, 
                              :parent_type => ss.class.to_s, 
                              :property => "wsdl_location")
              service_test = ServiceTest.new(:service_id => ss.service.id,
                                              :test_type => mon.class.name, :activated_at => Time.now )
              mon.service_test = service_test
              if mon.save!
                puts "Created new monitor for soap service id : #{ss.id}"
              end
           end
        end
      end
        
    end # MonitorUpdate
    
    class CheckUrlStatus
      

      # this function get the HTTP head from a url using curl
      # and checks the status code. OK if status code is 200, warning otherwise
      # eg curl -I http://www.google.com
      # Note : this only works on a system with curl system command

      def self.check_url_status(url)
        puts "checking url #{url}"
        status = {:action => 'http_head'}
        data = %x[curl -I --max-time 20 -X GET #{url}]
  
        pieces = data.split
        if pieces[1] =='200' and pieces[2] =='OK'   # status OK
          status.merge!({:result=> 0, :message => data})
        elsif pieces[1] =='302'                     # redirect means OK
          status.merge!({:result=> 0, :message => data})
        elsif pieces[1] =='400'                     # bad request means endpoint is available but needs curation
          status.merge!({:result=> 0, :message => data})
        else 
          status.merge!({:result=> 1, :message => data})
        end
    
        return status 
      end

      # Generate a soap fault by sending a non-intrusive xml to the service endpoint
      # then parse the soap message to see if the service implements soap correctly
      #
      # Example
      # curl --header "Content-Type: text/xml" --data "<?xml version="1.0"?>...." \
      #                                   http://opendap.co-ops.nos.noaa.gov/axis/services/Predictions
      #
      # Response :
      # <?xml version="1.0" encoding="UTF-8"?><soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
      # <soapenv:Body>
      # <soapenv:Fault>
      # <faultcode xmlns:ns1="http://xml.apache.org/axis/">ns1:Client.NoSOAPAction</faultcode>
      # <faultstring>no SOAPAction header!</faultstring>
      # <detail>
      # <ns2:hostname xmlns:ns2="http://xml.apache.org/axis/">opendap.co-ops.nos.noaa.gov</ns2:hostname>
      # </detail>
      # </soapenv:Fault>
      # </soapenv:Body>

      def self.generate_soap_fault(endpoint)
        puts "checking endpoint #{endpoint}"
        status = {:action => 'soap_fault'}
        data = %x[curl --max-time 20 --header "Content-Type: text/xml" --data "<?xml version="1.0"?>" #{endpoint}]
  
        pieces = data.split
        if pieces[0] == '<?xml'||'<soap:Envelope'
          status.merge!({:result=> 0, :message => data})
        else
          status.merge!({:result=> 1, :message => data})
        end
        return status
      end

      def self.check( *params)
        options = params.extract_options!.symbolize_keys
        options[:url] ||= options.include?(:url)
        options[:soap_endpoint] ||= options.include?(:soap_endpoint)
    
        if options[:url]
          check_url_status options[:url]
        elsif options[:soap_endpoint]
          generate_soap_fault options[:soap_endpoint] 
        else
          puts "No valid option selected"
        end
      end

      
      # check the status of urls ( endpoints & wsdl locations) 
      # Examples
      # To run on all the services in the database
      #     BioCatalogue::Monitoring::CheckUrlStatus.run :all => true
      # To run on specific services in the db
      #     BioCatalogue::Monitoring::CheckUrlStatus.run :service_ids => [1,2,3]
      def self.run (*params)
        options = params.extract_options!.symbolize_keys
        options[:service_ids] ||= options.include?(:service_ids)
        options[:all] ||= options.include?(:all)
        
        if options[:service_ids] and options[:all]
          puts "Seems we have a configuration problem"
          puts "Do not know what to do! Please either tell me what ids to check or tell me to check all, NOT both"
          return
        end
        
         if not options[:service_ids] and not options[:all]
          puts "Please run"
          puts "BioCatalogue::Monitoring::CheckUrlStatus.run :all => true"
          puts "to run monitoring on all the services OR"
          puts "BioCatalogue::Monitoring::CheckUrlStatus.run :service_ids => [some, service, ids]"
          puts "to run monitoring on the specified ids"
          return
        end
        
        if options[:all]
          monitors = UrlMonitor.find(:all)
        elsif options[:service_ids]
          monitors = []
          services = Service.find(options[:service_ids])
          services.each{ |s| 
                          s.service_deployments.each{|dep| monitors.concat(dep.url_monitors)}
                          s.service_version_instances_by_type('SoapService').each{ |instance|
                                  monitors.concat(instance.url_monitors)
                                }
                                
                        }
          
        end
        
        monitors.each do |monitor|
        #UrlMonitor.find(:all).each do |monitor|
          # get all the attributes of the services to be monitors
          # and run the checks agains them
          result = {}
          pingable = UrlMonitor.find_parent(monitor.parent_type, monitor.parent_id)
    
          if monitor.property =="endpoint" and pingable.service_version.service_versionified_type =="SoapService"
            # eg: check :soap_endpoint => pingable.endpoint
            result = check :soap_endpoint => pingable.send(monitor.property)
          else
              # eg: check :url => pingable.wsdl_location
            result = check :url => pingable.send(monitor.property)
          end
    
          # create a test result entry in the db to record
          # the current check for this URL/endpoint
          tr = TestResult.new(:result => result[:result],
                              :action => result[:action],
                              :message => result[:message],
                              :service_test_id => monitor.service_test.id)
          if tr.save!
            puts "Result for monitor id:  #{monitor.id} saved!"
          else
            puts "Ooops! Result for monitor id:  #{monitor.id} could not be saved!"
          end
        end
      end
  
    end #CheckUrlStatus
    
  end
end