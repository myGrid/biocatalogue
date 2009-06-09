# BioCatalogue: lib/bio_catalogue/monitoring.rb
#
# Copyright (c) 2009, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

module BioCatalogue
  module Monitoring
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
              if mon.save
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
    
              if mon.save
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
        data = %x[curl -I --max-time 20 #{url}]
  
        pieces = data.split
        if pieces[1] =='200' and pieces[2] =='OK'   # status OK
          status.merge!({:result=> 0, :message => data})
        elsif pieces[1] =='302'                     # redirect means OK
          status.merge!({:result=> 0, :message => data})
        else 
          status.merge!({:result=> 1, :message => data})
        end
    
        return status 
      end

      # Generate a soap fault by sending a non-intrusive xml to the service endpoint
      # then parse the soap message to see if the service implements soap correctly
      #curl --header "Content-Type: text/xml" --data "<?xml version="1.0"?>...." http://opendap.co-ops.nos.noaa.gov/axis/services/Predictions
      def self.generate_soap_fault(endpoint)
        puts "checking endpoint #{endpoint}"
        status = {:action => 'soap_fault'}
        data = %x[curl --max-time 20 --header "Content-Type: text/xml" --data "<?xml version="1.0"?>" #{endpoint}]
  
        pieces = data.split
        if pieces[0] == '<?xml'
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


      def self.run
    
        UrlMonitor.find(:all).each do |monitor|
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
          tr = TestResult.new(:test_id => monitor.id,
                        :test_type => monitor.class.to_s,
                        :result => result[:result],
                        :action => result[:action],
                        :message => result[:message] )
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