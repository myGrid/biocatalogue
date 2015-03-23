# BioCatalogue: lib/bio_catalogue/monitoring.rb
#
# Copyright (c) 2009-2011, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

module BioCatalogue
  module Monitoring


    
    INTERNAL_TEST_TYPES = [ 'TestScript', 'UrlMonitor' ].freeze
    
    def self.pingable_url(actual_string)
      string = actual_string.try(:text)
      string = actual_string unless !string.nil?
      string.each_line do |line|
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
        Service.all.each do |service|
          update_service_monitors(service)          
        end
      end
  
      # *** THIS IS FOR DEBUG PURPOSES ONLY ***
      def self.run_with_service_ids(*s_ids)
        Service.find(s_ids).each do |service|
          update_service_monitors(service)          
        end
      end
  
    protected 
      
      def self.update_service_monitors(service)
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
          
          update_user_created_monitors
        end
      end
      
      # from a list service deployments, check if
      # the endpoints are being monitored already.
      # If not, add the endpoint to the list of endpoints to
      # to monitor

      def self.update_deployment_monitors(deployments)
  
        deployments.each do |dep|
          monitor = UrlMonitor.first(:conditions => ["parent_id= ? AND parent_type= ?", dep.id, dep.class.to_s ])
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
          monitor = UrlMonitor.first(:conditions => ["parent_id= ? AND parent_type= ?", ss.id, ss.class.to_s ])
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
        Annotation.all(
                        :joins => :attribute,
                        :conditions => { :annotatable_type => 'RestMethod',
                        :annotation_attributes => { :name => "example_endpoint" } }).each  do |ann|
          update_monitor_for_annotation_and_service(ann, ann.annotatable.rest_resource.rest_service.service)
        end
      end # update_rest_service_monitors
      
      def self.update_user_created_monitors
        Annotation.all(
                        :joins => :attribute,
                        :conditions => { :annotatable_type => 'Service',
                        :annotation_attributes => { :name => "monitoring_endpoint" } }).each  do |ann|
          update_monitor_for_annotation_and_service(ann, ann.annotatable)
        end
      end
      
      def self.build_url_monitor(parent, property, service, max_monitors_per_service = 2)
        
        monitor_count = ServiceTest.all(:conditions => ["service_id=? AND test_type=?", service.id, "UrlMonitor"]).count
        
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
      
      # Is the "example_endpoint" or "monitoring_endpoint" annotation from a trusted source?
      # Anyone responsible for the service is considered a trusted 
      # source
      def self.from_trusted_source?(ann)
        if ann.attribute.name.downcase =="example_endpoint" && ann.annotatable.class.name == "RestMethod"
          if ann.source.class.name == "User" 
            return true if ann.annotatable.rest_resource.rest_service.service.all_responsibles.include?(ann.source)
          end
        end
        
        if ann.attribute.name.downcase =="monitoring_endpoint" && ann.annotatable.class.name == "Service"
          if ann.source.class.name == "User" 
            return true if ann.annotatable.all_responsibles.include?(ann.source)
          end
        end
        
        return false    
      end
      
      def self.update_monitor_for_annotation_and_service(ann, service)
        if from_trusted_source?(ann)
          can_be_monitored = !Monitoring.pingable_url(ann.value_content).nil?
          
          monitor = UrlMonitor.first(:conditions => ["parent_id= ? AND parent_type= ?", ann.id, ann.class.name ])
          
          # create new monitor if a pingable URL exists in annotation
          if monitor.nil? && can_be_monitored
            mon = build_url_monitor(ann, 'value_content', service)
            if mon
              begin
                if mon.save!
                  Rails.logger.debug("Created a new monitor for #{ann.value_content}")
                end
              rescue Exception => ex
                Rails.logger.warn("Could not create url monitor")
                Rails.logger.warn(ex)
              end
            end
          end
          
          # disable test for unpingable monitor
          if monitor && !can_be_monitored
            begin
              Rails.logger.warn("Disabling service test with ID: #{monitor.service_test.id} because it does not contain a valid pingable URI")
              monitor.service_test.deactivate!
            rescue Exception => ex
              Rails.logger.warn("Could not disable service test with ID: #{monitor.service_test.id}")
              Rails.logger.warn(ex)
            end
          end
        end # from_trusted_source?
      end
      
    end # MonitorUpdate
    
  # ==========
    
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

          # check if it a wms service
          service = WmsServiceNode.find_by_wms_service_id(@service_id)
          if !service.nil?
            # get GetCapabilities XML and check hash_value
            require 'net/http'
            request = URI.parse(url + "?request=getCapabilities&service=wms&version=" + service.version.to_s)

            req = Net::HTTP::Get.new(request.to_s)
            res = Net::HTTP.start(request.host, request.port) {|http| http.request(req) }

            # calculate cryptographic hash function
            # of getCapabilities XML
            require 'digest'
            hash = Digest::SHA1.hexdigest(res.body)

            if !service.hash_value.eql?hash
              service.hash_value = hash
              service.save!
              delete_wms_service(@service_id)
              parse_wms(res)
            end


          end
          status.merge!({:result=> 0, :message => check.response})
        else
          status.merge!({:result=> 1, :message => check.response})
        end
        return status 
      end


      def self.delete_wms_service(id)

        # delete keywords
        WmsKeywordlist.where(wms_service_node_id: id).find_each do |keyword|
          keyword.delete
        end

        # delete contact information
        WmsContactInformation.where(wms_service_node_id: id).find_each do |contactinfo|
          contactinfo.delete
        end

        # delete exception formats
        WmsExceptionFormat.where(wms_service_id: id).find_each do |exception|
          exception.delete
        end

        # delete getcapabiliteis_formats
        WmsGetcapabilitiesFormat.where(wms_service_id: id).find_each do |format|
          format.delete
        end

        # delete get_online_resources
        WmsGetcapabilitiesGetOnlineresource.where(wms_service_id: id).find_each do |geton|
          geton.delete
        end

        # delete post_online_resources
        WmsGetcapabilitiesPostOnlineresource.where(wms_service_id: id).find_each do |poston|
          poston.delete
        end

        # delete online_resources
        WmsOnlineResource.where(wms_service_node_id: id).find_each do |resource|
          resource.delete
        end

        # delete getmap_formats
        WmsGetmapFormat.where(wms_service_id: id).find_each do |getmapformat|
          getmapformat.delete
        end

        # delete getmap_get_online
        WmsGetmapGetOnlineresource.where(wms_service_id: id).find_each do |getonline|
          getonline.delete
        end

        # delete getmap_post_online
        WmsGetmapPostOnlineresource.where(wms_service_id: id).find_each do |postonline|
          postonline.delete
        end

        # find associated layers and delete
        WmsLayer.where(wms_service_id: id).find_each do |layer|
          delete_layer(layer)
        end

        # delete service itself
        WmsServiceNode.where(wms_service_id: id).find_each do |servicenode|
          servicenode.delete
        end

      end

      def self.delete_layer(layer)

        # delete keywords
        WmsKeywordlist.where(wms_layer_id: layer.id).find_each do |keyword|
          keyword.delete
        end

        # delete boundingboxes
        WmsLayerBoundingbox.where(wms_layer_id: layer.id).find_each do |bbox|
          bbox.delete
        end

        # delete crs
        WmsLayerCrs.where(wms_layer_id: layer.id).find_each do |crs|
          crs.delete
        end

        # delete styles
        WmsLayerStyle.where(wms_layer_id: layer.id).find_each do |style|
          style.delete
        end

        # find child layers and
        # recursively call this method
        WmsLayer.where(wms_layer_id: layer.id).find_each do |childlayer|
          delete_layer(childlayer)
        end

        # delete layer itself
        layer.delete

      end





      def self.parse_wms(res)

        # create REXML object
        doc = REXML::Document.new res.body
        require "rexml/document"

        # get version attribute from <wms_capabilities>
        @version = doc.root.attributes['version']
        # get <capability> and <service>
        capability_element = doc.elements[1].elements[2]
        service_element = doc.elements[1].elements[1]

        # call appropriate methods
        capabilityNode(capability_element)
        serviceNode(service_element)



      end

      # Method for parsing <Service> node
      def self.serviceNode(givenServiceNode)
        @onlineResources = []
        service = WmsServiceNode.new
        service.layer_count = @layer_count
        service.version = @version
        service.wms_service_id = @service_id
        @output = "Services <br />"

        # go through every child node
        for i in 1..givenServiceNode.elements.size
          if !givenServiceNode.elements[i].has_elements? and !givenServiceNode.elements[i].name.eql?("OnlineResource")

            # get node name of child
            @node = givenServiceNode.elements[i].name

            @text = givenServiceNode.elements[i].text

            if @text == nil
              @text="NO DATA"
            end

            if @node == "Name"
              service.name = @text
            end

            if @node == "Title"
              service.title = @text
            end

            if @node == "Abstract"
              service.abstract = @text
            end

            if @node == "Fees"
              service.fees = @text
            end

            if @node == "AccessConstraints"
              service.access_constraints = @text
            end

            if @node == "MaxWidth"
              service.max_width = @text
            end

            if @node == "MaxHeight"
              service.max_height = @text
            end

            @output = @output + @node + "  :  " + @text + "<br />"

          else
            # call switch method for routing
            switch(givenServiceNode.elements[i], service)
          end



        end

        # save everything
        service.save!
        @keywordlist.each do |element|
          element.wms_service_node_id = service.id
          element.wms_layer_id = nil
          element.save!
        end

        @onlineResources.each do |element|
          element.wms_service_node_id = service.id
          element.save!
        end

        @contact_information.wms_service_node_id = service.id;
        @contact_information.save!
      end

      # method for parsing <keywordlist>
      def self.keywordListNode(keywordListNode, belongsTo)
        @keywordlist = []
        @keywordlist23 = "KeywordList<br />"
        # go through every element
        for i in 1..keywordListNode.elements.size
          if !keywordListNode.elements[i].has_elements?
            # create new model and add it to array
            @keywordlist23 = @keywordlist23 + keywordListNode.elements[i].text + "<br />"
            keyword = WmsKeywordlist.new
            keyword.keyword = keywordListNode.elements[i].text
            @keywordlist << keyword

          end
        end
      end

      # method for parsing <OnlineResource>
      def self.onlineResourceNode(givenNode)
        # create new model
        online_resource = WmsOnlineResource.new
        if !givenNode.attributes["xmlns:link"].nil?
          online_resource.xmlns_link = givenNode.attributes["xmlns:link"]
        end

        if !givenNode.attributes["xlink:type"].nil?
          online_resource.xlink_type = givenNode.attributes["xlink:type"]
        end

        if !givenNode.attributes["xlink:href"].nil?
          online_resource.xlink_href = givenNode.attributes["xlink:href"]
        end

        # add to array to save later
        @onlineResources << online_resource
      end

      # method for <ContactInformation>
      def self.contactInformationNode(givenNode)
        # create new model
        @contact_information = WmsContactInformation.new


        # go through every child node
        for i in 1..givenNode.elements.size
          if !givenNode.elements[i].has_elements?
            # get current node name
            @node = givenNode.elements[i].name

            # get node text
            @text = givenNode.elements[i].text

            # find necessary information and add them to
            # appropriate fields of the model
            if @node == "ContactPerson"
              @contact_information.contact_person = @text
            end

            if @node == "ContactOrganization"
              @contact_information.contact_organization = @text
            end
            if @node == "ContactPosition"
              @contact_information.contact_position = @text
            end
            if @node == "AddressType"
              @contact_information.address_type = @text
            end
            if @node == "Address"
              @contact_information.address = @text
            end
            if @node == "City"
              @contact_information.city = @text
            end

            if @node == "StateOrProvince"
              @contact_information.state_or_province = @text
            end

            if @node == "PostCode"
              @contact_information.post_code = @text
            end

            if @node == "Country"
              @contact_information.country = @text
            end

          else
            # go though child's every child
            for j in 1..givenNode.elements[i].elements.size

              @node = givenNode.elements[i].elements[j].name

              @text = givenNode.elements[i].elements[j].text

              # find necessary information and add them to
              # appropriate fields of the model
              if @node == "ContactPerson"
                @contact_information.contact_person = @text
              end

              if @node == "ContactOrganization"
                @contact_information.contact_organization = @text
              end

              if @node == "ContactPosition"
                @contact_information.contact_position = @text
              end
              if @node == "AddressType"
                @contact_information.address_type = @text
              end
              if @node == "Address"
                @contact_information.address = @text
              end
              if @node == "City"
                @contact_information.city = @text
              end

              if @node == "StateOrProvince"
                @contact_information.state_or_province = @text
              end

              if @node == "PostCode"
                @contact_information.post_code = @text
              end

              if @node == "Country"
                @contact_information.country = @text
              end
            end
          end
        end


      end


      # method for parsing <Capability>
      def self.capabilityNode(givenCapabilityNode)
        # variable for counting layers
        @layer_count = 0

        # go through every child node
        for i in 1..givenCapabilityNode.elements.size
          @node = givenCapabilityNode.elements[i].name

          if @node == "Request"
            requestNode(givenCapabilityNode.elements[i])

            # save models
            @capability_formats.each do |element|
              element.wms_service_id = @service_id
              element.save!
            end

            @capability_get_resources.each do |element|
              element.wms_service_id = @service_id
              element.save!
            end


            @capability_post_resources.each do |element|
              element.wms_service_id = @service_id
              element.save!
            end


            @map_formats.each do |element|
              element.wms_service_id = @service_id
              element.save!
            end


            @map_get_resources.each do |element|
              element.wms_service_id = @service_id
              element.save!
            end


            @map_post_resources.each do |element|
              element.wms_service_id = @service_id
              element.save!
            end




          end


          # parse <Exception>
          if @node == "Exception"
            exceptionNode(givenCapabilityNode.elements[i])

            @exception_formats.each do |element|
              element.wms_service_id = @service_id
              element.save!
            end

          end

          if @node == "Layer"

            # pass layer for parsing
            layer = layerNode(givenCapabilityNode.elements[i], @service_id, nil)


          end
        end
      end


      # method for parsing <Request>
      def self.requestNode(givenNode)
        # initialize arrays
        @capability_formats = []
        @capability_get_resources = []
        @capability_post_resources = []
        @map_formats = []
        @map_get_resources = []
        @map_post_resources = []

        # go through children
        for i in 1..givenNode.elements.size

          # analyze GetCapabilites node
          if givenNode.elements[i].name == "GetCapabilities"
            for j in 1..givenNode.elements[i].elements.size
              @node = givenNode.elements[i].elements[j].name
              @text = givenNode.elements[i].elements[j].text

              # Format node
              if @node == "Format"
                formats = WmsGetcapabilitiesFormat.new
                formats.format = @text
                @capability_formats << formats
              end

              # DCPType node
              if @node == "DCPType"



                # HTTP node
                if givenNode.elements[i].elements[j].elements[1].name == "HTTP"

                  for l in 1..givenNode.elements[i].elements[j].elements[1].elements.size

                    #GET node
                    if givenNode.elements[i].elements[j].elements[1].elements[l].name == "Get"


                      for z in 1..givenNode.elements[i].elements[j].elements[1].elements[l].elements.size

                        # OnlineResource node
                        if givenNode.elements[i].elements[j].elements[1].elements[l].elements[z].name == "OnlineResource"
                          resource = WmsGetcapabilitiesGetOnlineresource.new
                          if !givenNode.elements[i].elements[j].elements[1].elements[l].elements[z].attributes["xmlns:link"].nil?
                            resource.xmlns_link = givenNode.elements[i].elements[j].elements[1].elements[l].elements[z].attributes["xmlns:link"]
                          end

                          if !givenNode.elements[i].elements[j].elements[1].elements[l].elements[z].attributes["xlink:type"].nil?
                            resource.xlink_type = givenNode.elements[i].elements[j].elements[1].elements[l].elements[z].attributes["xlink:type"]
                          end

                          if !givenNode.elements[i].elements[j].elements[1].elements[l].elements[z].attributes["xlink:href"].nil?
                            resource.xlink_href = givenNode.elements[i].elements[j].elements[1].elements[l].elements[z].attributes["xlink:href"]
                          end

                          @capability_get_resources << resource
                        end
                      end
                    end

                    #POST node
                    if givenNode.elements[i].elements[j].elements[1].elements[l].name == "Post"
                      for z in 1..givenNode.elements[i].elements[j].elements[1].elements[l].elements.size

                        # OnlineResource node
                        if givenNode.elements[i].elements[j].elements[1].elements[l].elements[z].name == "OnlineResource"
                          resource = WmsGetcapabilitiesPostOnlineresource.new
                          if !givenNode.elements[i].elements[j].elements[1].elements[l].elements[z].attributes["xmlns:link"].nil?
                            resource.xmlns_link = givenNode.elements[i].elements[j].elements[1].elements[l].elements[z].attributes["xmlns:link"]
                          end

                          if !givenNode.elements[i].elements[j].elements[1].elements[l].elements[z].attributes["xlink:type"].nil?
                            resource.xlink_type = givenNode.elements[i].elements[j].elements[1].elements[l].elements[z].attributes["xlink:type"]
                          end

                          if !givenNode.elements[i].elements[j].elements[1].elements[l].elements[z].attributes["xlink:href"].nil?
                            resource.xlink_href = givenNode.elements[i].elements[j].elements[1].elements[l].elements[z].attributes["xlink:href"]
                          end

                          @capability_post_resources << resource
                        end
                      end
                    end
                  end
                end
              end

            end
          end

          # analyze GetMap node
          if givenNode.elements[i].name == "GetMap"

            for j in 1..givenNode.elements[i].elements.size
              @node = givenNode.elements[i].elements[j].name
              @text = givenNode.elements[i].elements[j].text

              # Format node
              if @node == "Format"
                formats = WmsGetmapFormat.new
                formats.format = @text
                @map_formats << formats
              end

              # DCPType node
              if @node == "DCPType"



                # HTTP node
                if givenNode.elements[i].elements[j].elements[1].name == "HTTP"

                  for l in 1..givenNode.elements[i].elements[j].elements[1].elements.size

                    #GET node
                    if givenNode.elements[i].elements[j].elements[1].elements[l].name == "Get"


                      for z in 1..givenNode.elements[i].elements[j].elements[1].elements[l].elements.size

                        # OnlineResource node
                        if givenNode.elements[i].elements[j].elements[1].elements[l].elements[z].name == "OnlineResource"
                          resource = WmsGetmapGetOnlineresource.new
                          if !givenNode.elements[i].elements[j].elements[1].elements[l].elements[z].attributes["xmlns:link"].nil?
                            resource.xmlns_link = givenNode.elements[i].elements[j].elements[1].elements[l].elements[z].attributes["xmlns:link"]
                          end

                          if !givenNode.elements[i].elements[j].elements[1].elements[l].elements[z].attributes["xlink:type"].nil?
                            resource.xlink_type = givenNode.elements[i].elements[j].elements[1].elements[l].elements[z].attributes["xlink:type"]
                          end

                          if !givenNode.elements[i].elements[j].elements[1].elements[l].elements[z].attributes["xlink:href"].nil?
                            resource.xlink_href = givenNode.elements[i].elements[j].elements[1].elements[l].elements[z].attributes["xlink:href"]
                          end

                          @map_get_resources << resource
                        end
                      end
                    end

                    #POST node
                    if givenNode.elements[i].elements[j].elements[1].elements[l].name == "Post"
                      for z in 1..givenNode.elements[i].elements[j].elements[1].elements[l].elements.size

                        # OnlineResource node
                        if givenNode.elements[i].elements[j].elements[1].elements[l].elements[z].name == "OnlineResource"
                          resource = WmsGetmapPostOnlineresource.new
                          if !givenNode.elements[i].elements[j].elements[1].elements[l].elements[z].attributes["xmlns:link"].nil?
                            resource.xmlns_link = givenNode.elements[i].elements[j].elements[1].elements[l].elements[z].attributes["xmlns:link"]
                          end

                          if !givenNode.elements[i].elements[j].elements[1].elements[l].elements[z].attributes["xlink:type"].nil?
                            resource.xlink_type = givenNode.elements[i].elements[j].elements[1].elements[l].elements[z].attributes["xlink:type"]
                          end

                          if !givenNode.elements[i].elements[j].elements[1].elements[l].elements[z].attributes["xlink:href"].nil?
                            resource.xlink_href = givenNode.elements[i].elements[j].elements[1].elements[l].elements[z].attributes["xlink:href"]
                          end

                          @map_post_resources << resource
                        end
                      end
                    end
                  end
                end
              end

            end

          end

        end

      end

      # analyze Exception node
      def self.exceptionNode(givenNode)
        @exception_formats = []
        for a in 1..givenNode.elements.size

          @node = givenNode.elements[a].name
          @text = givenNode.elements[a].text
          if @text == nil
            @text = "NO DATA"
          end


          if @node == "Format"
            formats = WmsExceptionFormat.new
            formats.format = @text
            @exception_formats << formats
          end
        end


      end

      # analyze Layer node
      def self.layerNode(givenNode, parentServiceNodeID, parentLayerNodeID)
        # initialize arrays to store layer details
        crss = []
        boundingboxes = []
        layers = []
        keywordlist_layer = []
        styles = []
        layer = WmsLayer.new
        @layer_count = @layer_count + 1
        # go through children
        for i in 1..givenNode.elements.size

          if !givenNode.elements[i].has_elements?
            # get node name and text
            @node = givenNode.elements[i].name

            @text = givenNode.elements[i].text

            if @text == nil
              @text="NO DATA"
            end

            # fill appropriate model fields
            if @node == "Name"
              layer.name = @text
            end

            if @node == "Title"
              layer.title = @text
            end

            if @node == "Abstract"
              layer.abstract = @text
            end
          end

          if givenNode.elements[i].name == "EX_GeographicBoundingBox"

            # go through child's children
            for a in 1..givenNode.elements[i].elements.size

              # get name and text
              @node = givenNode.elements[i].elements[a].name

              @text = givenNode.elements[i].elements[a].text

              if @text == nil
                @text="0"
              end

              if @node == "westBoundLongitude"
                layer.west_bound_longitude = @text
              end

              if @node == "eastBoundLongitude"
                layer.east_bound_longitude = Float(@text)
              end

              if @node == "southBoundLatitude"
                layer.south_bound_latitude = @text
              end

              if @node == "northBoundLatitude"
                layer.north_bound_latitude = @text
              end
            end
          end

          # create a CRS entry and add it to the array to save to db later on
          if givenNode.elements[i].name == "CRS"
            crs = WmsLayerCrs.new
            crs.crs = givenNode.elements[i].text
            crss << crs
          end

          # <BoundingBox>
          if givenNode.elements[i].name == "BoundingBox"
            boundingbox = WmsLayerBoundingbox.new

            if !givenNode.elements[i].attributes["CRS"].nil?
              boundingbox.crs = givenNode.elements[i].attributes["CRS"]
            end
            if !givenNode.elements[i].attributes["minx"].nil?
              boundingbox.minx = givenNode.elements[i].attributes["minx"]
            end
            if !givenNode.elements[i].attributes["miny"].nil?
              boundingbox.miny = givenNode.elements[i].attributes["miny"]
            end
            if !givenNode.elements[i].attributes["maxx"].nil?
              boundingbox.maxx = givenNode.elements[i].attributes["maxx"]
            end
            if !givenNode.elements[i].attributes["maxy"].nil?
              boundingbox.maxy = givenNode.elements[i].attributes["maxy"]
            end

            boundingboxes << boundingbox
          end

          # <KeywordList>
          if givenNode.elements[i].name == "KeywordList"
            #keywordlist_layer = []
            # go through every element
            for a in 1..givenNode.elements[i].elements.size
              keyword = WmsKeywordlist.new
              keyword.keyword = givenNode.elements[i].elements[a].text
              keyword.wms_service_node_id = nil
              keywordlist_layer << keyword
            end
          end

          # parse Style
          if givenNode.elements[i].name == "Style"
            style = WmsLayerStyle.new
            # go through every element
            for a in 1..givenNode.elements[i].elements.size


              if givenNode.elements[i].elements[a].name == "Name"
                style.name = givenNode.elements[i].elements[a].text
              elsif givenNode.elements[i].elements[a].name == "Title"
                style.title = givenNode.elements[i].elements[a].text
              elsif givenNode.elements[i].elements[a].name == "Abstract"
                style.abstract = givenNode.elements[i].elements[a].text
              end
              styles << style

            end

          end

          if givenNode.elements[i].name == "Layer"
            layers << givenNode.elements[i];
          end




        end

        # save layer
        layer.wms_service_id = parentServiceNodeID
        layer.wms_layer_id = parentLayerNodeID
        layer.save!

        # save crs
        crss.each do |element|
          element.wms_layer_id = layer.id
          element.save!
        end

        # save bbox
        boundingboxes.each do |element|
          element.wms_layer_id = layer.id
          element.save!
        end

        # save keywordlist
        if !keywordlist_layer.nil?
          keywordlist_layer.each do |element|
            element.wms_layer_id = layer.id
            element.save!
          end

        end

        # save style
        if !styles.nil?
          styles.each do |element|
            element.wms_layer_id = layer.id
            element.save!
          end

        end

        # parse inner layers using recursive calls
        if !layers.nil?
          layers.each { |element| layerNode(element, nil, layer.id) }
        end
        return layer
      end

      # switch method
      def self.switch(givenNode, belongsTo)
        case givenNode.name
          when "KeywordList", "keywordlist", "Keywordlist", "keywordList"
            keywordListNode(givenNode, belongsTo)
          when "OnlineResource", "onlineresource", "Onlineresource", "onlineResource"
            onlineResourceNode(givenNode)
          when "ContactInformation", "contactinformation", "Contactinformation", "contactInformation"
            contactInformationNode(givenNode)
        end
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
          monitors = UrlMonitor.all
        elsif options[:service_ids]
          monitors = []
          services = Service.find(options[:service_ids])
          services.each { |s| 
            s.service_tests.each { |st| monitors << st.test if st.test_type == "UrlMonitor" }
          }
        end
        
        monitors.each do |monitor|
        #UrlMonitor.all.each do |monitor|
          # get all the attributes of the services to be monitors
          # and run the checks agains them

          # keep the service id to use while checking XML hash value
          @service_id = monitor.parent_id

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
                    
                    result[:message] = "Endpoint: #{pingable_string}\n" + result[:message]
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