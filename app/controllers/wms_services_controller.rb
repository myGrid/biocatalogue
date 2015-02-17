require 'addressable/uri'

class WmsServicesController < ApplicationController


  before_filter :disable_action, :only => [ :edit, :update, :destroy ]
  before_filter :disable_action_for_api, :except => [ :index, :show, :create, :annotations, :deployments, :resources, :methods ]

  before_filter :login_or_oauth_required, :except => [ :index, :show, :annotations, :deployments, :resources, :methods ]

  before_filter :find_service_deployment, :only => [ :edit_base_endpoint_by_popup, :update_base_endpoint ]

  before_filter :authorise, :only => [ :edit_base_endpoint_by_popup, :update_base_endpoint ]

  before_filter :find_wms_service, :only => [ :show, :annotations, :deployments, :resources, :methods ]

  before_filter :parse_sort_params, :only => :index
  before_filter :find_wms_services, :only => :index


  oauth_authorize :create



  def test


    #require 'net/http'
    #require "rexml/document"

    # get the XML document
    #url = URI.parse('http://sampleserver1.arcgisonline.com/ArcGIS/services/Specialty/ESRI_StatesCitiesRivers_USA/MapServer/WMSServer?service=WMS&request=GetCapabilities&version=1.3.0')
    #url = URI.parse('http://www.gebco.net/data_and_products/gebco_web_services/web_map_service/mapserv?request=getCapabilities&service=wms&version=1.1.1')
    #url = URI.parse('http://geo.vliz.be/geoserver/ows?service=wms&version=1.3.0&request=GetCapabilities')
    #url = URI.parse('http://geoservices.brgm.fr/geologie?SERVICE=WMS&VERSION=1.3.0&REQUEST=GetCapabilities')
    #url = URI.parse(uri)

    #req = Net::HTTP::Get.new(url.to_s)
    #res = Net::HTTP.start(url.host, url.port) {|http| http.request(req) }

    request = params[:endpoint] + "?request=getCapabilities&service=wms&version=" + params[:version]

    require 'net/http'

    #url = URI.parse('http://sampleserver1.arcgisonline.com/ArcGIS/services/Specialty/ESRI_StatesCitiesRivers_USA/MapServer/WMSServer?service=WMS&request=GetCapabilities&version=1.3.0')


    #url = URI.parse('http://www.gebco.net/data_and_products/gebco_web_services/web_map_service/mapserv?request=getCapabilities&service=wms&version=1.1.1')
    url = URI.parse(request)
    req = Net::HTTP::Get.new(url.to_s)
    res = Net::HTTP.start(url.host, url.port) {|http| http.request(req) }



    # create REXML object
    doc = REXML::Document.new res.body

    @version = doc.root.attributes['version']
    service_element = doc.elements[1].elements[1]
    capability_element = doc.elements[1].elements[2]

    serviceNode(service_element)
    capabilityNode(capability_element)


  end

  def serviceNode(givenServiceNode)
    @onlineResources = []
    service = WmsServiceNode.new
    service.version = @version
    service.wms_service_id = @service.service_id  # <<<--------------------------------------------
    @output = "Services <br />"
    for i in 1..givenServiceNode.elements.size
      if !givenServiceNode.elements[i].has_elements? and !givenServiceNode.elements[i].name.eql?("OnlineResource")
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
=begin
        if givenServiceNode.elements[i].name.eql?("OnlineResource")
          @output = @output + "OnlineResource  :  " + givenServiceNode.elements[i].attributes["xlink:type"] + givenServiceNode.elements[i].attributes["xlink:href"] + "<br />"
        end
=end
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
    #@keywordlist.each { |element| element.wms_layer_id = nil }
    #@keywordlist.each { |element| element.save! }
    @onlineResources.each do |element|
      element.wms_service_node_id = service.id
      element.save!
    end
    #@onlineResources.each { |element| element.save! }
    @contact_information.wms_service_node_id = service.id;
    @contact_information.save!
  end


  def keywordListNode(keywordListNode, belongsTo)
    @keywordlist = []
    @keywordlist23 = "KeywordList<br />"
    # go through every element
    for i in 1..keywordListNode.elements.size
      if !keywordListNode.elements[i].has_elements?
        @keywordlist23 = @keywordlist23 + keywordListNode.elements[i].text + "<br />"
        keyword = WmsKeywordlist.new
        keyword.keyword = keywordListNode.elements[i].text
        @keywordlist << keyword

      end
    end
  end

  def onlineResourceNode(givenNode)
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

    @onlineResources << online_resource
  end


  def contactInformationNode(givenNode)
    @contact_information = WmsContactInformation.new


    for i in 1..givenNode.elements.size
      if !givenNode.elements[i].has_elements?
        @node = givenNode.elements[i].name

        @text = givenNode.elements[i].text

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
        for j in 1..givenNode.elements[i].elements.size

          @node = givenNode.elements[i].elements[j].name

          @text = givenNode.elements[i].elements[j].text

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



  def capabilityNode(givenCapabilityNode)
    for i in 1..givenCapabilityNode.elements.size
      @node = givenCapabilityNode.elements[i].name

      if @node == "Request"
        requestNode(givenCapabilityNode.elements[i])
        @capability_formats.each do |element|
          element.wms_service_id = @service.service_id             # TO BE CHANGED <<<_--------------
          element.save!
        end

        #@capability_formats.each { |element| element.save! }

        @capability_get_resources.each do |element|
          element.wms_service_id = @service.service_id             # TO BE CHANGED <<<_--------------
          element.save!
        end


        #@capability_get_resources.each { |element| element.save! }

        @capability_post_resources.each do |element|
          element.wms_service_id = @service.service_id     # TO BE CHANGED <<<_--------------
          element.save!
        end
        #@capability_post_resources.each { |element| element.save! }

        @map_formats.each do |element|
          element.wms_service_id = @service.service_id     # TO BE CHANGED <<<_--------------
          element.save!
        end


        @map_get_resources.each do |element|
          element.wms_service_id = @service.service_id      # TO BE CHANGED <<<_--------------
          element.save!
        end


        @map_post_resources.each do |element|
          element.wms_service_id = @service.service_id      # TO BE CHANGED <<<_--------------
          element.save!
        end




      end

      if @node == "Exception"
        exceptionNode(givenCapabilityNode.elements[i])

        @exception_formats.each do |element|
          element.wms_service_id = @service.service_id      # TO BE CHANGED <<<_--------------
          element.save!
        end

      end

      if @node == "Layer"
        layer = layerNode(givenCapabilityNode.elements[i], @service.service_id, nil)              # TO BE CHANGED <<<_--------------
=begin
        layer.wms_service_id = 9     # TO BE CHANGED <<<_--------------
        layer.save!
        @crss.each { |element| element.wms_layer_id = layer.id }
        @crss.each { |element| element.save! }
        @boundingboxes.each { |element| element.wms_layer_id = layer.id }
        @boundingboxes.each { |element|
          element.save!
        }
        if !@keywordlist_layer.nil?
          @keywordlist_layer.each { |element| element.wms_layer_id = layer.id }
          @keywordlist_layer.each { |element| element.save! }
        end
=end

      end
    end
  end


  def requestNode(givenNode)
    @capability_formats = []
    @capability_get_resources = []
    @capability_post_resources = []
    @map_formats = []
    @map_get_resources = []
    @map_post_resources = []

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
  def exceptionNode(givenNode)
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
  def layerNode(givenNode, parentServiceNodeID, parentLayerNodeID)
    crss = []
    boundingboxes = []
    layers = []
    keywordlist_layer = []
    styles = []
    layer = WmsLayer.new
    for i in 1..givenNode.elements.size

      if !givenNode.elements[i].has_elements?
        @node = givenNode.elements[i].name

        @text = givenNode.elements[i].text

        if @text == nil
          @text="NO DATA"
        end

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
        for a in 1..givenNode.elements[i].elements.size
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

    layer.wms_service_id = parentServiceNodeID
    layer.wms_layer_id = parentLayerNodeID
    layer.save!
    crss.each do |element|
      element.wms_layer_id = layer.id
      element.save!
    end

    boundingboxes.each do |element|
      element.wms_layer_id = layer.id
      element.save!
    end


    if !keywordlist_layer.nil?
      keywordlist_layer.each do |element|
        element.wms_layer_id = layer.id
        element.save!
      end

    end

    if !styles.nil?
      styles.each do |element|
        element.wms_layer_id = layer.id
        element.save!
      end

    end

    if !layers.nil?
      layers.each { |element| layerNode(element, nil, layer.id) }
    end
    return layer
  end










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



  # GET /wms_services
  # GET /wms_services.xml
  def index
    respond_to do |format|
      format.html { disable_action }
      format.xml # index.xml.builder
      format.json { render :json => BioCatalogue::Api::Json.index("wms_services", json_api_params, @wms_services).to_json }
    end
  end

  # GET /wms_services/1
  # GET /wms_services/1.xml
  def show
    @test = "b;ahkjdsklfj"
    respond_to do |format|
      format.html { disable_action }
      format.xml  # show.xml.builder
      format.json { render :json => @wms_service.to_json }
    end
  end

  # GET /wms_services/new
  # GET /wms_services/new.xml

  def new
    @wms_service = WmsService.new
    params[:annotations] = { }

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @wms_service }
    end
  end


  # POST /wms_services
  # Example Input:
  #
  #  {
  #   "wms_service" => {
  #      "name" => "official name"
  #    },
  #    "endpoint" => "http://www.example.com",
  #    "annotations" => {
  #      "documentation_url" => "doc",
  #      "alternative_names" => ["alt1", "alt2", "alt3"],
  #      "tags" => ["t1", "t3", "t2"],
  #      "description" => "desc",
  #      "categories" => [ <list of category URIs> ]
  #    }
  #  }

  def create
    endpoint = params[:endpoint] || ""
    endpoint.chomp!
    endpoint.strip!
    if !endpoint.blank? && endpoint =~ /^http[s]?:\/\/\S+/
      endpoint = Addressable::URI.parse(endpoint).normalize.to_s unless endpoint.blank?
      status = BioCatalogue::AvailabilityCheck::URLCheck.new(endpoint).available?
      if !status
        message = 'The URL you have provided could not be reached. Please ensure the URL is correct and that your service is running.'
        endpoint = ''
      end
    else
      endpoint = ''
      message = 'Please provide a valid endpoint URL'
    end


    if endpoint.blank?
      flash.now[:error] = message
      respond_to do |format|
        format.html { render :action => "new" }
        # TODO: implement format.xml  { render :xml => '', :status => 406 }
        format.json { error_to_back_or_home(message, false, 406) }
      end
    else
      if is_api_request? # Sanitize for API Request
        category_ids = []

        params[:annotations] ||= {}
        params[:annotations][:categories] ||= []

        params[:annotations][:categories].compact.each { |cat| category_ids << BioCatalogue::Api.object_for_uri(cat.to_s).id if BioCatalogue::Api.object_for_uri(cat.to_s) }
        params[:annotations][:categories] = category_ids
      end

      # Check for a duplicate
      existing_service = WmsService.check_duplicate(endpoint)

      if !existing_service.nil?
        # Because the service already exists, add any information provided by the user as additional annotations to the existing service.

        annotations_data = params[:annotations].clone

        # Special case for alternative name annotations...
        main_name = params[:wms_service][:name]
        annotations_data[:alternative_name] = params[:wms_service][:name] if !main_name.blank? && !existing_service.name.downcase.eql?(main_name.downcase)

        # Now create them...
        existing_service.latest_version.service_versionified.process_annotations_data(annotations_data, current_user)

        respond_to do |format|
          flash[:notice] = "The service you specified already exists in #{SITE_NAME}. See below. Any information you provided has been added to this service."
          format.html { redirect_to existing_service }
          # TODO: implement format.xml  { render :xml => '', :status => :unprocessable_entity }
          format.json {
            render :json => {
                :success => {
                    :message => "The WMS service you specified already exists in #{SITE_NAME}. Any information you provided has been added to this service.",
                    :resource => service_url(existing_service)
                }
            }.to_json, :status => 202
          }
        end
      else
        has_missing_elements = params[:wms_service].blank? || params[:wms_service][:name].blank? || params[:wms_service][:name].chomp.strip.blank?
        if is_api_request? && has_missing_elements
          respond_to do |format|
            format.html { disable_action }
            format.json { error_to_back_or_home("Please provide a valid name for the WMS Service you wish to create.", false, 406) }
          end
        else
          # Now you can submit the service...
          @wms_service = WmsService.new
          @wms_service.name = params[:wms_service][:name].chomp.strip


#-------------------------------------------------------------------- test
          #request = params[:endpoint] + "?request=getCapabilities&service=wms&version=1.3.0"

          #require 'net/http'

          #url = URI.parse('http://sampleserver1.arcgisonline.com/ArcGIS/services/Specialty/ESRI_StatesCitiesRivers_USA/MapServer/WMSServer?service=WMS&request=GetCapabilities&version=1.3.0')


          #url = URI.parse('http://www.gebco.net/data_and_products/gebco_web_services/web_map_service/mapserv?request=getCapabilities&service=wms&version=1.1.1')
          #url = URI.parse(request)
          #req = Net::HTTP::Get.new(url.to_s)
          #@res = Net::HTTP.start(url.host, url.port) {|http| http.request(req) }


          #object_hash = Hash.from_xml(res.body)

          #key = object_hash.keys[0]
          #xml_hash = object_hash[key]
          #@name = xml_hash['Service']['Name']
          #@title = xml_hash['Service']['Title']
          #@xml = "Name:   " + @name + "<br>" + "Title:   " + @title


#-------------------------------------------------------------------------------

          #@wms_service_parameter = WmsServiceParameter.new
          #@wms_service_parameter.xml_content = res.body

          respond_to do |format|
            results = @wms_service.submit_service(endpoint, current_user, params[:annotations].clone)
             if results[0]
              @service = results[1]
              test
              success_msg = 'Service was successfully submitted.'.html_safe
              success_msg += "<br/>You may now add endpoints via the Endpoints tab.".html_safe


              flash[:notice] = success_msg
              format.html { redirect_to(@wms_service.service(true)) }
              # TODO: implement format.xml  { render :xml => @wms_service, :status => :created, :location => @wms_service }
              # format.json { render :json => @wms_service.service(true).to_json }
              format.json {
                render :json => {
                    :success => {
                        :message => "The WMS Service '#{@wms_service.name}' has been successfully submitted.",
                        :resource => service_url(@wms_service.service(true))
                    }
                }.to_json, :status => 201
              }
            else
              err_text = "An error has occurred with the submission.<br/>".html_safe +
                  "Please <a href='/contact'>contact us</a> if you need assistance with this.".html_safe
              flash.now[:error] = err_text
              format.html { render :action => "new" }
              # TODO: implement format.xml  { render :xml => '', :status => 500 }
              format.json { error_to_back_or_home("An error has occurred with the submission.", false, 500) }





            end
          end
        end
      end
    end
  end

  def edit_base_endpoint_by_popup
    respond_to do |format|
      format.js { render :layout => false }
    end
  end

  def update_base_endpoint
    endpoint = params[:new_endpoint] || ""
    endpoint.chomp!
    endpoint.strip!
    if !endpoint.blank? && endpoint =~ /^http[s]?:\/\/\S+/
      endpoint = Addressable::URI.parse(endpoint).normalize.to_s
    else
      endpoint = ''
    end

    not_changed = params[:new_endpoint] == @service_deployment.endpoint
    exists = !WmsService.check_duplicate(endpoint).nil?

    if endpoint.blank? || not_changed || exists
      flash[:error] = (not_changed || exists ?
          "The endpoint you are trying to submit already exists in the system" :
          "Please provide a valid endpoint URL")

      respond_to do |format|
        format.html { redirect_to @service_deployment.service }
        format.xml  { render :xml => '', :status => 406 }
      end
    else
      @service_deployment.endpoint = endpoint
      @service_deployment.save!


      flash[:notice] = "The base URL has been successfully changed"

      respond_to do |format|
        format.html { redirect_to @service_deployment.service }
        format.xml  { head :ok }
      end
    end

  end

  def annotations
    respond_to do |format|
      format.html { disable_action }
      format.xml { redirect_to(generate_include_filter_url(:ars, @wms_service.id, "annotations", :xml)) }
      format.json { redirect_to(generate_include_filter_url(:ars, @wms_service.id, "annotations", :json)) }
    end
  end

  def resources
    respond_to do |format|
      format.html { disable_action }
      format.xml  # deployments.xml.builder
      format.json { render :json => @wms_service.to_custom_json("wms_resources") }
    end
  end

  def deployments
    respond_to do |format|
      format.html { disable_action }
      format.xml  # deployments.xml.builder
      format.json { render :json => @wms_service.to_custom_json("deployments") }
    end
  end

  def methods
    respond_to do |format|
      format.html { disable_action }
      format.xml  # methods.xml.builder
      format.json { render :json => @wms_service.to_custom_json("wms_methods") }
    end
  end

  protected # ========================================

  def find_wms_service
    @wms_service = WmsService.find(params[:id], :include => :service)
  end

  def authorise
    unless BioCatalogue::Auth.allow_user_to_curate_thing?(current_user, @service_deployment)
      error_to_back_or_home("You are not allowed to perform this action")
      return false
    end

    return true
  end

  def parse_sort_params
    sort_by_allowed = [ "created" ]
    @sort_by = if params[:sort_by] && sort_by_allowed.include?(params[:sort_by].downcase)
                 params[:sort_by].downcase
               else
                 "created"
               end

    sort_order_allowed = [ "asc", "desc" ]
    @sort_order = if params[:sort_order] && sort_order_allowed.include?(params[:sort_order].downcase)
                    params[:sort_order].downcase
                  else
                    "desc"
                  end
  end

  def find_service_deployment
    @service_deployment = ServiceDeployment.find(params[:service_deployment_id])
  end

  def find_wms_services

    # Sorting

    order = 'wms_services.created_at DESC'
    order_field = nil
    order_direction = nil

    case @sort_by
      when 'created'
        order_field = "created_at"
    end

    case @sort_order
      when 'asc'
        order_direction = 'ASC'
      when 'desc'
        order_direction = "DESC"
    end

    unless order_field.blank? or order_direction.nil?
      order = "wms_services.#{order_field} #{order_direction}"
    end

    @wms_services = WmsService.paginate(:page => @page,
                                          :per_page => @per_page,
                                          :order => order)
  end



  def edit
  end
end
