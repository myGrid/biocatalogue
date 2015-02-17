class WmsServiceLayerController < ApplicationController
  def show
    @layer = WmsLayer.find_by_id(params[:id ])


=begin
    @bboxes = "<select>"
    @bboxes = @bboxes + "<option>{bounding boxes}</option>"
    WmsLayerBoundingbox.where(wms_layer_id: layer.id).find_each do |bbox|
      if @version == "1.3.0"
        data = "<br />&bbox=" + bbox.minx + "," + bbox.miny + ","+ bbox.maxx + "," + bbox.maxy + "&crs=" + bbox.crs;
      else
        data = "<br />&bbox=" + bbox.minx + "," + bbox.miny + ","+ bbox.maxx + "," + bbox.maxy + "&srs=" + bbox.crs;
      end

      @bboxes = @bboxes + "<option data-req=\"" + data + "\">" + bbox.crs + " | " + bbox.minx + " | " + bbox.miny + " | " + bbox.maxx + " | " + bbox.maxy + "</option>"
    end
    @bboxes = @bboxes + "</select>"
=end

    @script1 = "<script type='text/javascript'>
    function change(a, id)
    {

      document.getElementById(id).innerHTML = a.options[a.selectedIndex].getAttribute('data-req');

    }
    </script>"

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

    layer(params[:id])
    @template = "<br /><b>" + @base + "?Service=wms&Request=GetMap&Version=" + @version +
                "<br />&layers=" + @layer.name +
                "<br />&format=<span id=\"1\">{OUTPUT FORMAT}</span>" +
                "<br />&styles=<span id=\"2\">{STYLES}</span>"

    if @version == "1.3.0"
      @template = @template + "<br />&crs=<span id=\"3\">{CRS and BOUNDING BOXES}</span>"
    else
      @template = @template + "<br />&srs=<span id=\"3\">{SRS and BOUNDING BOXES}</span>"
    end

    @template = @template + "<br />&height=" + @max_height.to_s + "<br />&width=" + @max_width.to_s

=begin
    @template = "<b>" + @baseURL + "&layers=" + layer.name +
        "<span class=\"imagePart\"><br />{format}</span><br />&styles=<span id=\"" + @counter.to_s +
        "\"></span><span id=\"" + (@counter+1).to_s +
        "\"><br />{Bounding Boxes}</span><span><br />&height=" + @maxHeight.to_s +
        "</span><span><br />&width=" + @maxWidth.to_s + "</span></b>"
=end


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
      @bboxes = @bboxes + "<option data-req=\"" + @bbcrs[i] + @bbparams[i] + "\">" + @bbcrs[i] + " | " + @bbreadable[i] + "</option>"
    end
    @bboxes = @bboxes + "</select>"

    @template = @template + "</b><br />"

    @output = @script1 + "<br />Select output format:<br />" + @imageformats +
              "<br />Select CRS and Bounding Boxes values:<br />" + @bboxes +
              "<br />Select output style(if any):<br />" + @sty +
              "<br /><br />" + @template

  end

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
    WmsLayerStyle.where(wms_layer_id: layerID).find_each do |style|
       @styles << style.name
    end


    layer = WmsLayer.find_by_id(layerID)
    if layer.wms_service_id.nil? or layer.wms_service_id == ""
      # call parent layer node
      layer(layer.wms_layer_id)
    else
      # no layer node above this one
      WmsGetmapFormat.where(wms_service_id: layer.wms_service_id).find_each do |format|
        @formats << format.format
      end

      @base = ServiceDeployment.find_by_service_id(layer.wms_service_id).endpoint
      service = WmsServiceNode.find_by_wms_service_id(layer.wms_service_id)
      @version = service.version
      @max_height = service.max_height
      @max_width = service.max_width
    end


  end
end
