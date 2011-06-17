# BioCatalogue: lib/bio_catalogue/monitoring.rb
#
# Copyright (c) 2009, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

module BioCatalogue
  module Monitoring
    
    INTERNAL_TEST_TYPES = [ 'TestScript', 'UrlMonitor' ].freeze
    
    def self.pingable_url(actual_string)
      actual_string.each_line do |line|
        line.chomp.split(' ').each do |token|
          token.strip!
          
          next unless token.downcase.starts_with?("http://") || token.downcase.starts_with?("https://")
          
          begin
            uri = URI.parse(token)
            return uri.to_s
          rescue
            # ignoring any errors
          end
        end
      end
      
      return nil
    end

    class MonitorUpdate
    
      def self.run
        Service.find(:all).each do |service|
          
          # de-activate service tests if archived
          if service.archived?
            service.deactivate_service_tests!
          else
            #service.activate_service_tests!

            # get all service deployments
            deployments = service.service_deployments
    
            #register the end-points for monitoring
            update_deployment_monitors(deployments)
    
            #get all service instances(soap & rest)
            instances = service.service_version_instances
    
            soap_services = instances.delete_if{ |instance| instance.class.to_s != "SoapService" }
            update_soap_service_monitors(soap_services)
            update_rest_service_monitors
          end
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
              begin
                if mon.save!
                  Rails.logger.debug("Created new monitor for deployment id : #{dep.id}")
                end
              rescue Exception => ex
                Rails.logger.warn("Failed to create a monitor :")
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
            begin
              if mon.save!
                Rails.logger.debug("Created new monitor for soap service id : #{ss.id}")
              end
            rescue Exception => ex
              Rails.logger.warn("Failed to create a monitor for Service : #{ss.id}")
              Rails.logger.warn(ex)
            end
          end
        end
      end
      
      def self.update_rest_service_monitors(*params)
        
        Annotation.find(:all, 
                        :joins => :attribute,
                        :conditions => { :annotatable_type => 'RestMethod',
                        :annotation_attributes => { :name => "example_endpoint" } }).each  do |ann|
          
          if from_trusted_source?(ann)
            can_be_monitored = !Monitoring.pingable_url(ann.value).nil?
            
            monitor = UrlMonitor.find(:first , :conditions => ["parent_id= ? AND parent_type= ?", ann.id, ann.class.name ])
            
            # create new monitor if a pingable URL exists in annotation
            if monitor.nil? && can_be_monitored
              mon = build_url_monitor(ann, 'value', ann.annotatable.rest_resource.rest_service.service)
              if mon
                begin
                  if mon.save!
                    Rails.logger.debug("Created a new monitor for #{ann.send('value')}")
                  end
                rescue Exception => ex
                  Rails.logger.warn("Could not create url monitor")
                  Rails.logger.warn(ex)
                end
              end
            end
            
            # delete invalid monitor
            if monitor && !can_be_monitored
              begin
                Rails.logger.warn("Deleting url monitor with ID: #{monitor.id}")
                UrlMonitor.delete(monitor.id)
              rescue Exception => ex
                Rails.logger.warn("Could not delete url monitor with ID: #{monitor.id}")
                Rails.logger.warn(ex)
              end
            end
            
          end # from_trusted_source?
        end
      end # update_rest_service_monitors
      
      def self.build_url_monitor(parent, property, service, max_monitors_per_service = 2)
        
        monitor_count = ServiceTest.find(:all , :conditions => ["service_id=? AND test_type=?", service.id, "UrlMonitor"]).count
        
        if monitor_count < max_monitors_per_service
          mon = UrlMonitor.new(:parent_id => parent.id, 
                              :parent_type => parent.class.name, 
                              :property => property)
          service_test = ServiceTest.new(:service_id => service.id,
                                              :test_type => mon.class.name, :activated_at => Time.now )
          mon.service_test = service_test
          return mon
        else
          return nil
        end
        
      end
      
      # Is the "example_endpoint" annotation from a trusted source?
      # Anyone responsible for the service is considered a trusted 
      # source
      def self.from_trusted_source?(ann)
        if ann.attribute.name.downcase =="example_endpoint" && ann.annotatable.class.name == "RestMethod"
          if ann.source.class.name == "User" 
            return true if ann.annotatable.rest_resource.rest_service.service.all_responsibles.include?(ann.source)
          end
        end
        return false    
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
        check =  BioCatalogue::AvailabilityCheck::URLCheck.new(url)
        if check.available?
          status.merge!({:result=> 0, :message => check.response}) 
        else
          status.merge!({:result=> 1, :message => check.response})
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

        ep =  BioCatalogue::AvailabilityCheck::SoapEndPoint.new(endpoint)
        if ep.available?
          status.merge!({:result=> 0, :message => ep.parser.document}) 
        else
          status.merge!({:result=> 1, :message => ep.parser.document})
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
          services.each { |s| 
            s.service_tests.each { |st| monitors << st.test if st.test_type == "UrlMonitor" }
          }
        end
        
        monitors.each do |monitor|
        #UrlMonitor.find(:all).each do |monitor|
          # get all the attributes of the services to be monitors
          # and run the checks agains them
          if monitor.service_test.activated?
            result = {}
            pingable = UrlMonitor.find_parent(monitor.parent_type, monitor.parent_id)
            if pingable
              was_monitored = true
              
              if monitor.property =="endpoint" and pingable.service_version.service_versionified_type =="SoapService"
                # eg: check :soap_endpoint => pingable.endpoint
                result = check :soap_endpoint => pingable.send(monitor.property)
                if result[:result] != 0
                  if pingable.service_version.service_versionified.endpoint_available?
                    result[:result]   = 0
                    result[:message]  = "Connected to service"
                    result[:action]   = "soap_client"
                  end
                end
              else
                # eg: check :url => pingable.wsdl_location
                if pingable.class == Annotation
                  actual_string = pingable.send(monitor.property) # try and get a pingable value from the annotation
                  pingable_string = Monitoring.pingable_url(actual_string)
                  
                  if pingable_string.nil?
                    was_monitored = false
                  else
                    result = check :url => pingable_string
                    result[:message] = "Example-Endpoint: #{pingable_string}\n" + result[:message]    
                  end
                else
                  result = check :url => pingable.send(monitor.property)
                end
              end
              
              if was_monitored
                # create a test result entry in the db to record
                # the current check for this URL/endpoint               
                tr = TestResult.new(:result => result[:result],
                                    :action => result[:action],
                                    :message => result[:message],
                                    :service_test_id => monitor.service_test.id)
                                      
                begin
                  if tr.save!
                    Rails.logger.debug("Result for monitor id:  #{monitor.id} saved!")
                  end
                rescue Exception => ex
                  Rails.logger.warn("Result for monitor id:  #{monitor.id} could not be saved!")
                  Rails.logger.warn(ex)
                end
              end # was_monitored
              
            end
          end
        end
      end
            
    end #CheckUrlStatus
         
  end
end