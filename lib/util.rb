# BioCatalogue: app/lib/util.rb
#
# Copyright (c) 2008, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

#require 'geo_kit/geocoders'
require 'dnsruby'
require 'addressable/uri'
require 'timeout'

module BioCatalogue
  module Util
    #include GeoKit::Geocoders
    
    @@logger = RAILS_DEFAULT_LOGGER
    
    # Attempts to lookup the geographical location of the URL provided.
    # This uses the GeoKit plugin to do the geocoding.
    # Returns a Gecode::GeoLoc object if successful, otherwise returnes nil.
    def self.url_location_lookup(url)
      return nil if url.blank?
      
      loc = Util.ip_geocode(Dnsruby::Resolv.getaddress(Addressable::URI.parse(url).host))
      return loc.success ? loc : nil 
    rescue
      @@logger.error("Method BioCatalogue::Util.url_location_lookup errored. Exception:")
      @@logger.error($!)
      return nil
    end
    
    # This method borrows code/principles from the GeoKit plugin.
    def self.ip_geocode(ip)
      geoloc = GeoKit::GeoLoc.new
            
      return geoloc unless /^(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})?$/.match(ip)
      
      url = "http://api.hostip.info/get_html.php?ip=#{ip}&position=true"
      
      info = ''
      
      begin
        timeout(5) { info = open(url, :proxy => HTTP_PROXY).read }
      rescue TimeoutError
        @@logger.error("Method BioCatalogue::Util.ip_geocode - timeout occurred when attempting to get info from HostIp.")
        return geoloc
      rescue
        @@logger.error("Method BioCatalogue::Util.ip_geocode - failed on call to HostIp. Exception:")
        @@logger.error($!)
        return geoloc
      end
      
      # Process the info into the GeoKit GeoLoc object...
      unless info.blank?
        yaml = YAML.load(info)
        geoloc.provider = 'hostip'
        geoloc.city, geoloc.state = yaml['City'].split(', ')
        country, geoloc.country_code = yaml['Country'].split(' (')
        geoloc.lat = yaml['Latitude'] 
        geoloc.lng = yaml['Longitude']
        geoloc.country_code.chop!
        geoloc.success = true unless geoloc.country_code == "XX"
      end
      
      return geoloc
    end
    
    def self.city_and_country_from_geoloc(geoloc)
      return [ ] unless geoloc.is_a?(GeoKit::GeoLoc)
      return [ ] if geoloc.nil? or !geoloc.success
      
      city = nil
      country = nil
      
      unless geoloc.city == "(Private Address)" or geoloc.city == "(Unknown City)"
        city = geoloc.city
      end
      
      country = CountryCodes.country(geoloc.country_code)
      
      return [ city, country ]
    end
    
    # This method groups together a collection of model objects into sub groups by model name.
    #  
    # If 'sub_group_types' is provided, it will only collect the sub groups of the types specified.
    # 'sub_group_types' should be an array of pluralized and underscored model names. 
    # E.g: [ "services", "soap_operations", "service_providers" ] 
    #
    # If "discover_associated" is set to true AND 'sub_group_types' is specified, 
    # for each item in 'model_objects' this method will attempt to discover 
    # parent/associated model objects that match each group type in 'sub_group_types'.
    #    
    # Returns an array where:
    # - The first element is the total count of items in all sub groups.
    # - The second element is a hash of sub grouped objects in the following form:
    #   { "Model1Name" => [ obj1, obj2, ... ], "Model2Name" => [ obj3, obj4, obj5, ..., ... }
    def self.group_model_objects(model_objects, sub_group_types=nil, discover_associated=false)
      total_count = 0
      grouped = { }
      
      if discover_associated and !sub_group_types.nil?
        group_type_models = sub_group_types.map{|t| t.classify.constantize}
        group_type_models.each do |m|
          m_name = m.to_s
          grouped[m_name] = self.discover_model_objects_from_collection(m, model_objects)
          total_count = total_count + grouped[m_name].length
        end
      else
        model_objects.each do |t|
          if (arr = grouped[(klass = t.class.name)])
            arr << t
          else
            grouped[klass] = [ t ]
          end
        end
        
        if sub_group_types.nil?
          total_count = model_objects.length
        else
          # Filter out the types we don't want
          total_count = 0
          group_type_model_names = sub_group_types.map{|t| t.classify}
          grouped.each do |m_name, objs|
            if group_type_model_names.include?(m_name)
              total_count += objs.length
            else
              grouped.delete(m_name)
            end
          end
        end
      end
      
      return [ total_count, grouped ]
    end
    
    # Given a disparate collection of ActiveRecord model items, 
    # this method attempts to find and return a list of items only  
    # of the class 'model' (specified), based on associations from 
    # each individual item.
    #
    # E.g: if the model specified is Service and the items contains a 
    # ServiceVersion, then the .service association of that ServiceVersion 
    # will be added into the collection returned back.
    #
    # 'model' must be a Class representing the ActiveRecord model in question.
    #
    # NOTE: currently only supports Service for the 'model' parameter for
    # association finding. But other models can still be used - will just 
    # find items of the same class.
    def self.discover_model_objects_from_collection(model, items)
      model_items = [ ]
      
      items.each do |item|
        if item.is_a?(ActiveRecord::Base)
          if item.is_a?(model)
            model_items << item
          else
            case model.to_s
              when "Service"
                @@logger.info "BioCatalogue::Util.discover_model_objects_from_collection - model required = Service;"
                case item
                  when ServiceVersion, 
                       ServiceDeployment, 
                       SoapService,
                       RestService
                    model_items << item.service
                  when SoapOperation  
                    model_items << item.soap_service.service unless item.soap_service.nil?
                  when SoapInput, SoapOutput  
                    model_items << item.soap_operation.soap_service.service unless item.soap_operation.nil? or item.soap_operation.soap_service.nil?
                  when Annotation
                    if ["Service", 
                        "ServiceVersion", 
                        "ServiceDeployment", 
                        "SoapService", 
                        "SoapOperation", 
                        "SoapInput", 
                        "SoapOutput",
                        "RestService"].include?(item.annotatable_type)
                      model_items.concat(Util.discover_model_objects_from_collection(Service, [ item.annotatable ]))
                    end
                  else
                    @@logger.info "BioCatalogue::Util.discover_model_objects_from_collection - model required = Service; item type = #{item.class.name}, no way to get a top level Service for the item."
                end
            end
          end
        end
      end
      
      return model_items.uniq
    end
    
    # This utility method takes a hash of annotations data and does some preprocessing on them.
    # This is at a higher level than the processing done by the Annotations plugin,
    # and is mainly just to rearrange/restructure the data in the annotations_data hash so that
    # it is in a more appropriate format to be used when creating annotations out of it.
    # (e.g.: when used in the create_annotations method).
    #
    # Fields with a nil value will be removed.
    #
    # The following attribute specific processing is applied:
    #   - for :tags -
    #       it will transform { :tags => "test1, test2, test3" } into { :tag => [ "test1", "test2", "test3" ] } 
    #
    # NOTE: for preprocessing to work on attributes, the keys MUST be symbols, NOT strings.
    #       Keys with strings will still be returned back but no preprocessing will occur on them.
    def self.preprocess_annotations_data(annotations_data)
      # Remove fields that have a nil value
      annotations_data.keys.each do |attrib|
        annotations_data.delete(attrib) if annotations_data.has_key?(attrib) && annotations_data[attrib].nil?
      end
      
      # :tags to :tag
      if annotations_data.has_key?(:tags)
        annotations_data[:tag] = annotations_data[:tags].split(',').map{|x| x.strip}
        annotations_data.delete(:tags)
      end
      
      return annotations_data
    end
    
    # Helper method to get the ratings categories configuration hash for a specific model type.
    # This acts as a lookup table for ratings configuration to models and allows us to maintain different
    # ratings configurations for different models.
    def self.get_ratings_categories_config_for_model(model)
      ratings_config = { }
      
      case model.name
        when "Service", "SoapService", "RestService"  
          ratings_config = SERVICE_RATINGS_CATEGORIES
      end
      
      return ratings_config
    end
    
    # Returns a new hash with the contents duplicated from the params hash provided.
    # Note: this should not be used as a guaranteed deep copy mechanism, rather it is especially for
    # the params hash generated by ActionController and mainly used for things like the filtering/faceting.
    def self.duplicate_params(params)
      return Marshal.load(Marshal.dump(params))
    end
  end
end