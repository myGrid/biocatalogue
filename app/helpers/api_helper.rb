# BioCatalogue: app/helpers/api_helper.rb
#
# Copyright (c) 2008-2009, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details.

module ApiHelper
  
  include ApplicationHelper
  
  def xml_root_attributes
    { "xmlns" => "http://www.biocatalogue.org/2009/xml/rest",
      "xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance",
      "xsi:schemaLocation" => "http://www.biocatalogue.org/2009/xml/rest " + URI.join(SITE_BASE_HOST, "2009/xml/rest/schema-v1.xsd").to_s,
      "xmlns:xlink" => "http://www.w3.org/1999/xlink",
      "xmlns:dcterms" => "http://purl.org/dc/terms/" }
  end
  
  def uri_for_collection(resource_name, *args)
    options = args.extract_options!
    # defaults:
    options.reverse_merge!(:params => nil)        
    
    uri = ""
    
    unless resource_name.blank?
      uri = URI.join(SITE_BASE_HOST, resource_name).to_s
      uri = append_params(uri, options[:params]) unless options[:params].blank?
    end
    
    return uri
  end
  
  def uri_for_object(resource_obj, *args)
    options = args.extract_options!
    # defaults:
    options.reverse_merge!(:params => nil,
                           :sub_path => nil)
                           
    uri = ""
    
    unless resource_obj.nil?
      resource_part = "#{resource_obj.class.name.pluralize.underscore}/#{resource_obj.id}"
      unless options[:sub_path].blank?
        sub_path = options[:sub_path]
        sub_path = "/#{sub_path}" unless sub_path.starts_with?('/')
        resource_part += sub_path
      end
      uri = URI.join(SITE_BASE_HOST, resource_part).to_s
      uri = append_params(uri, options[:params]) unless options[:params].blank?
    end
    
    return uri
  end
      
  def xml_for_filters(builder, filters, filter_key)
    return nil if builder.nil? or filters.blank?
    
    filter_key_humanised = BioCatalogue::Filtering.filter_type_to_display_name(filter_key).singularize.downcase
    
    filters.each do |f|
      
      attribs = xlink_attributes(generate_include_filter_url(filter_key, f["id"]), :title => xlink_title("Filter by #{filter_key_humanised}: '#{f['name'].downcase}'"))
      attribs.update({
        :urlValue => f["id"],
        :name => f["name"],
        :count => f['count']
      })
      
      builder.filter attribs  do
                 
        xml_for_filters(builder, f["children"], filter_key)

      end
        
    end
  end
  
  def previous_link_xml_attributes(resource_uri)
    xlink_attributes(resource_uri, :title => xlink_title("Next page of results"))
  end
  
  def next_link_xml_attributes(resource_uri)
    xlink_attributes(resource_uri, :title => xlink_title("Previous page of results"))
  end
  
  def xlink_attributes(resource_uri, *args)
    attribs = { }
    
    attribs_in = args.extract_options!
    
    attribs["xlink:href"] = resource_uri
    
    attribs_in.each do |k,v|
      attribs["xlink:#{k.to_s}"] = v
    end

    return attribs
  end
  
  def xlink_title(item, item_type_name=nil)
    case item
      when String
        return item
      else
        if item_type_name.blank?
          return "#{item.class.name.titleize} - #{display_name(item)}"
        else
          return "#{item_type_name} - #{display_name(item)}"
        end
    end
  end
  
  def dcterms_xml_tags(builder, *args)
    attribs_in = args.extract_options!
    
    attribs_in.each do |k,v|
      # Certain fields need some more processing...
      
      # Dates
      if [ :created, :modified ].include?(k)
        v = v.iso8601
      end
      
      builder.tag! "dcterms:#{k}", v 
    end
  end
  
  protected
      
  def append_params(uri, params)
    # Remove the special params
    new_params = BioCatalogue::Util.remove_rails_special_params_from(params)
    return (new_params.blank? ? uri : "#{uri}?#{new_params.to_query}")
  end

end