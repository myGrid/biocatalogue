class WmsServiceLayerController < ApplicationController
  def show

    # get the layer
    @layer = WmsLayer.find_by_id(params[:id ])

    # JavaScript for changing template parameters interactively
    @script1 = "<script type='text/javascript'>
    function change(a, id)
    {

      document.getElementById(id).innerHTML = a.options[a.selectedIndex].getAttribute('data-req');

    }
    </script>"

    # initialize variables
    @bbparams = []
    @bbreadable = []
    @bbcrs = []
    @styles = []
    @formats = []
    @base
    @version
    @max_height
    @max_width
    @imageformats
    @version = '1.3.0' #TODO: Set version correctly

    # get layer parameters
    layer(params[:id])

    # generated template
    @template = "<br /><b>" + @base.to_s + "?Service=wms&Request=GetMap&Version=" + @version.to_s +
                "<br />&layers=" + @layer.name +
                "<br />&format=<span id=\"1\">{OUTPUT FORMAT}</span>" +
                "<br />&styles=<span id=\"2\">{STYLES}</span>"

    if @version == "1.3.0"
      @template = @template + "<br />&crs=<span id=\"3\">{CRS and BOUNDING BOXES}</span>"
    else
      @template = @template + "<br />&srs=<span id=\"3\">{SRS and BOUNDING BOXES}</span>"
    end

    @template = @template + "<br />&height=" + @max_height.to_s + "<br />&width=" + @max_width.to_s



    # create image formats dropdown list
    @imageformats = "<select onChange=\"change(this, 1)\">"
    @imageformats = @imageformats + "<option>Please select</option>"
    @formats.each do |format|
      @imageformats = @imageformats + "<option data-req=\"" + format + "\">" + format + "</option>"
    end
    @imageformats = @imageformats + "</select>"

    # create styles dropdown list
    @sty = "<select onChange=\"change(this, 2)\">"
    @sty = @sty + "<option>Please select</option>"
    @styles.each do |format|
      @sty = @sty + "<option data-req=\"" + format + "\">" + format + "</option>"
    end
    @sty = @sty + "</select>"


    # create bbox dropdown list
    @bboxes = "<select onChange=\"change(this, 3)\">"
    @bboxes = @bboxes + "<option>Please select</option>"
    for i in 0..@bbparams.size-1
      @bboxes = @bboxes.to_s + "<option data-req=\"" + @bbcrs[i].to_s + '' + @bbparams[i].to_s + "\">" + @bbcrs[i].to_s + " | " + @bbreadable[i].to_s + "</option>"
    end
    @bboxes = @bboxes + "</select>"

    @template = @template + "</b><br />"

    # put everything in a single output string
    @output = @script1 + "<br />Select output format:<br />" + @imageformats +
              "<br />Select CRS and Bounding Boxes values:<br />" + @bboxes +
              "<br />Select output style(if any):<br />" + @sty +
              "<br /><br />" + @template

  end

  # method for collecting all the specific layer information
  def layer(layerID)

    # get bounding boxes
    WmsLayerBoundingbox.where(wms_layer_id: layerID).find_each do |bbox|
      bb = "&bbox=" + bbox.minx + "," + bbox.miny + ","+ bbox.maxx + "," + bbox.maxy
      bb2 = bbox.minx + " | " + bbox.miny + " | "+ bbox.maxx + " | " + bbox.maxy
      @bbparams << bb
      @bbreadable << bb2
      @bbcrs << bbox.crs
    end

    # get layer styles
=begin
    WmsLayerStyle.where(wms_layer_id: layerID).find_each do |style|
       @styles << style.name
    end
=end


    layer = WmsLayer.find_by_id(layerID)
    puts "\n\n\n\ #{layer.inspect} === #{layer.wms_service_id}"
    if layer.wms_service_id.nil? or layer.wms_service_id == ''
      # call parent layer node
      puts layer.wms_layer_id
      layer(layer.wms_layer_id)
    else
      # no layer node above this one
      WmsGetmapFormat.where(wms_service_id: layer.wms_service_id).find_each do |format|
        @formats << format.format
      end

      @base = ServiceDeployment.find_by_service_id(layer.wms_service_id)
      if !@base.nil?
        @base = @base.endpoint
      end
      service = WmsServiceNode.find_by_wms_service_id(layer.wms_service_id)
      if !service.nil?
        @version = service[:version].to_s
        @max_height = service[:max_height].to_s
        @max_width = service[:max_width].to_s
      end

    end


  end
end
