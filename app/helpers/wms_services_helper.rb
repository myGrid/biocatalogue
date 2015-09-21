module WmsServicesHelper
  include ApplicationHelper

  def parse(res)


    #require 'net/http'
    require "rexml/document"

    # get the XML document
    #url = URI.parse('http://sampleserver1.arcgisonline.com/ArcGIS/services/Specialty/ESRI_StatesCitiesRivers_USA/MapServer/WMSServer?service=WMS&request=GetCapabilities&version=1.3.0')
    #url = URI.parse('http://www.gebco.net/data_and_products/gebco_web_services/web_map_service/mapserv?request=getCapabilities&service=wms&version=1.1.1')
    #url = URI.parse('http://geo.vliz.be/geoserver/ows?service=wms&version=1.3.0&request=GetCapabilities')
    #url = URI.parse('http://geoservices.brgm.fr/geologie?SERVICE=WMS&VERSION=1.3.0&REQUEST=GetCapabilities')
    #url = URI.parse(uri)

    # create REXML object
    doc = REXML::Document.new res.body

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
  def serviceNode(givenServiceNode)
    @onlineResources = []
    service = WmsServiceNode.new
    service[:layer_count] = @layer_count
    service[:version] = @version
    service[:wms_service_id] = @service.service_id
    @output = "Services <br />"

    # go through every child node
    for i in 1..givenServiceNode.elements.size
      # if child of service node has children and this child is not OnlineResource
      if !givenServiceNode.elements[i].has_elements? and !givenServiceNode.elements[i].name.eql?("OnlineResource")

        # get node name of child
        @node = givenServiceNode.elements[i].name

        # get the text of child
        @text = givenServiceNode.elements[i].text

        if @text == nil
          @text="NO DATA"
        end

        # assign service name
        if @node == "Name"
          service.name = @text
        end

        # assign service title
        if @node == "Title"
          service.title = @text
        end

        # assign abstract
        if @node == "Abstract"
          service.abstract = @text[0...100]
        end

        # assign service fees
        if @node == "Fees"
          service.fees = @text[0...100]
        end

        # assign access contraints of the service
        if @node == "AccessConstraints"
          service.access_constraints = @text[0...100]
        end

        # assign maximum width value
        if @node == "MaxWidth"
          service.max_width = @text
        end

        # assign maxiimum height value
        if @node == "MaxHeight"
          service.max_height = @text
        end

        #
        @output = @output + @node + "  :  " + @text + "<br />"

      else
        # call switch method for routing
        switch(givenServiceNode.elements[i], service)
      end



    end

    # save service node
    service.save!

    # assign service node's id and save
    @keywordlist.each do |element|
      element.wms_service_node_id = service.id
      # since it is service's keywords, layer is null
      element.wms_layer_id = nil
      element.save!
    end

    # assign service node's id and save
    @onlineResources.each do |element|
      element.wms_service_node_id = service.id
      element.save!
    end

    # assign service node's id and save
    @contact_information.wms_service_node_id = service.id;
    @contact_information.save!
  end


  # method for parsing <keywordlist>
  def keywordListNode(keywordListNode, belongsTo)
    @keywordlist = []
    @keywordlist23 = "KeywordList<br />"
    # go through child every element
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
  def onlineResourceNode(givenNode)
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
  def contactInformationNode(givenNode)
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
          @contact_information[:contact_person] = @text
        end

        if @node == "ContactOrganization"
          @contact_information[:contact_organization] = @text
        end
        if @node == "ContactPosition"
          @contact_information[:contact_position] = @text
        end
        if @node == "AddressType"
          @contact_information[:address_type]= @text
        end
        if @node == "Address"
          @contact_information[:address] = @text
        end
        if @node == "City"
          @contact_information[:city] = @text
        end

        if @node == "StateOrProvince"
          @contact_information[:state_or_province]= @text
        end

        if @node == "PostCode"
          @contact_information[:post_code] = @text
        end

        if @node == "Country"
          @contact_information[:country] = @text
        end

      else
        # go though child's every child
        for j in 1..givenNode.elements[i].elements.size

          # get node name
          @node = givenNode.elements[i].elements[j].name

          # get node text
          @text = givenNode.elements[i].elements[j].text

          # find necessary information and add them to
          # appropriate fields of the model
          if @node == "ContactPerson"
            @contact_information[:contact_person] = @text
          end

          if @node == "ContactOrganization"
            @contact_information[:contact_organization] = @text
          end

          if @node == "ContactPosition"
            @contact_information[:contact_position] = @text
          end
          if @node == "AddressType"
            @contact_information[:address_type] = @text
          end
          if @node == "Address"
            @contact_information[:address] = @text
          end
          if @node == "City"
            @contact_information[:city] = @text
          end

          if @node == "StateOrProvince"
            @contact_information[:state_or_province] = @text
          end

          if @node == "PostCode"
            @contact_information[:post_code] = @text
          end

          if @node == "Country"
            @contact_information[:country] = @text
          end
        end
      end
    end


  end



  # method for parsing <Capability>
  def capabilityNode(givenCapabilityNode)
    # variable for counting layers
    puts givenCapabilityNode
    @layer_count = 0
    # go through every child node
    for i in 1..givenCapabilityNode.elements.size

      # get node name
      @node = givenCapabilityNode.elements[i].name

      if @node == "Request"
        # pass request to for parsing
        requestNode(givenCapabilityNode.elements[i])

        # save models
        @capability_formats.each do |element|
          element[:wms_service_id] = @service.service_id
          element.save!
        end

        @capability_get_resources.each do |element|
          element.wms_service_id = @service.service_id
          element.save!
        end

        @capability_post_resources.each do |element|
          element.wms_service_id = @service.service_id
          element.save!
        end


        @map_formats.each do |element|
          element.wms_service_id = @service.service_id
          element.save!
        end


        @map_get_resources.each do |element|
          element.wms_service_id = @service.service_id
          element.save!
        end


        @map_post_resources.each do |element|
          element.wms_service_id = @service.service_id
          element.save!
        end




      end

      # parse <Exception>
      if @node == "Exception"
        exceptionNode(givenCapabilityNode.elements[i])

        @exception_formats.each do |element|
          element.wms_service_id = @service.service_id      # TO BE CHANGED <<<_--------------
          element.save!
        end

      end

      if @node == "Layer"

        # pass layer for parsing
        layer = layerNode(givenCapabilityNode.elements[i], @service.service_id, nil)              # TO BE CHANGED <<<_--------------

      end
    end
  end


  # method for parsing <Request>
  def requestNode(givenNode)
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
          # get node name and text
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

                      # add to array to save later
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

                      # add to array to save later
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

        # go throgh children
        for j in 1..givenNode.elements[i].elements.size
          # get node name and text
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

                      # add to array to save later
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

                      # add to array to save later
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
  def exceptionNode(givenNode)
    # init array
    @exception_formats = []
    # go through every child node
    for a in 1..givenNode.elements.size

      # get node name and text
      @node = givenNode.elements[a].name
      @text = givenNode.elements[a].text
      if @text == nil
        @text = "NO DATA"
      end

      # create new model and add to array to save later
      if @node == "Format"
        formats = WmsExceptionFormat.new
        formats.format = @text
        @exception_formats << formats
      end
    end


  end

  # analyze Layer node
  def layerNode(givenNode, parentServiceNodeID, parentLayerNodeID)
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
        # create a model and fill fields
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

        # go through every element
        for a in 1..givenNode.elements[i].elements.size
          keyword = WmsKeywordlist.new
          keyword.keyword = givenNode.elements[i].elements[a].text
          # this keywords belong to layer, not to service node
          keyword.wms_service_node_id = nil
          keywordlist_layer << keyword
        end
      end


      # parse Style

=begin
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
=end

      # store inner layers in array to parse later
      if givenNode.elements[i].name == "Layer"
        layers << givenNode.elements[i];
      end




    end

    # save layer
    layer[:wms_service_id] = parentServiceNodeID
    layer[:wms_layer_id]= parentLayerNodeID
    layer.save!

    # save crs
    crss.each do |element|
      element.wms_layer_id = layer.id
      element.save!
    end

    # save bboxes
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
  def switch(givenNode, belongsTo)
    case givenNode.name
      when "KeywordList", "keywordlist", "Keywordlist", "keywordList"
        keywordListNode(givenNode, belongsTo)
      when "OnlineResource", "onlineresource", "Onlineresource", "onlineResource"
        onlineResourceNode(givenNode)
      when "ContactInformation", "contactinformation", "Contactinformation", "contactInformation"
        contactInformationNode(givenNode)
    end
  end

end
