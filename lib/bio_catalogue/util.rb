# BioCatalogue: lib/bio_catalogue/util.rb
#
# Copyright (c) 2008, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

module BioCatalogue
  module Util
    
    # Attempts to lookup the geographical location of the URL provided.
    # This uses the GeoKit plugin to do the geocoding.
    # Returns a Gecode::GeoLoc object if successful, otherwise returnes nil.
    def self.url_location_lookup(url)
      begin
        return nil if url.blank?
        
        address = ""
        
        SystemTimer::timeout(4) { address = Dnsruby::Resolv.getaddress(Addressable::URI.parse(url).host) }
        
        loc = Util.ip_geocode(address)
        
        return loc.success ? loc : nil
      rescue TimeoutError
        Rails.logger.error("Method BioCatalogue::Util.url_location_lookup - timeout occurred when attempting to perform DNS resolution.")
        Rails.logger.error($!)
        return nil
      rescue Exception => ex
        Rails.logger.error("Method BioCatalogue::Util.url_location_lookup errored. Exception:")
        Rails.logger.error($!)
        return nil
      end
    end
    
    # This method borrows code/principles from the GeoKit plugin.
    def self.ip_geocode(ip)
      geoloc = GeoKit::GeoLoc.new
            
      return geoloc unless /^(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})?$/.match(ip)
      
      url = "http://api.hostip.info/get_html.php?ip=#{ip}&position=true"
      
      info = ''
      
      begin
        SystemTimer::timeout(4) { info = open(url, :proxy => HTTP_PROXY).read }
      rescue TimeoutError
        Rails.logger.error("Method BioCatalogue::Util.ip_geocode - timeout occurred when attempting to get info from HostIp.")
        Rails.logger.error($!)
        return geoloc
      rescue Exception => ex
        Rails.logger.error("Method BioCatalogue::Util.ip_geocode - failed on call to HostIp. Exception:")
        Rails.logger.error($!)
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
    # parent/ancestor/associated model objects that match each group type in 'sub_group_types'.
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
                Rails.logger.info "BioCatalogue::Util.discover_model_objects_from_collection - model required = Service;"
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
                    Rails.logger.info "BioCatalogue::Util.discover_model_objects_from_collection - model required = Service; item type = #{item.class.name}, no way to get a top level Service for the item."
                end
            end
          end
        end
      end
      
      return model_items.uniq
    end
    
    # Returns a new hash with the contents duplicated from the params hash provided.
    # Note: this should not be used as a guaranteed deep copy mechanism, rather it is especially for
    # the params hash generated by ActionController and mainly used for things like the filtering/faceting.
    def self.duplicate_params(params)
      return Marshal.load(Marshal.dump(params))
    end
    
    # This method removes the special Rails parameters from a params hash provided.   
    #
    # NOTE: the provided params collection will not be affected. 
    # Instead, a new hash will be returned. 
    def self.remove_rails_special_params_from(params, additional_to_remove=[])
      return { } if params.blank?
      
      special_params = %w( id format controller action commit ).concat(additional_to_remove)
      return params.reject { |k,v| special_params.include?(k.to_s.downcase) }
    end
    
    # For info/debug messages
    def self.say(msg)
      puts msg
      Rails.logger.info msg
    end
    
    # For warning messages
    def self.warn(msg)
      puts msg
      Rails.logger.warn msg
    end
    
    # For error messages
    def self.yell(msg)
      puts msg
      Rails.logger.error msg
    end
    
    # Utility method to get all the 'values' from a Hash as a single list.
    # This takes into account inner Hashes and inner Arrays. 
    def self.all_values_from_hash(h)
      values = [ ]
      
      return values if h.blank? or !h.is_a?(Hash)
      
      h.each do |k,v|
        if v.is_a?(Hash)
          values.concat(all_values_from_hash(v))
        elsif v.is_a?(Array)
          values.concat(all_values_from_array(v))
        else
          values << v.to_s
        end
      end
      
      return values
    end
    
    def self.all_values_from_array(a)
      values = [ ]
      
      return values if a.blank? or !a.is_a?(Array)
      
      a.each do |v|
        if v.is_a?(Hash)
          values.concat(all_values_from_hash(v))
        elsif v.is_a?(Array)
          values.concat(all_values_from_array(v))
        else
          values << v.to_s
        end
      end
      
      return values
    end
    
    def self.find_wsdl_file_for(obj)
      return nil unless BioCatalogue::Mapper::SOAP_SERVICE_STRUCTURE_MODELS.include?(obj.class)
      
      case obj
        when SoapService
          return obj.wsdl_file
        when SoapOperation
          return obj.soap_service.wsdl_file
        when SoapInput, SoapOutput
          return obj.soap_operation.soap_service.wsdl_file
        else
          return nil
      end
    end
    
    def self.display_name(item, escape_html=true)
      # NOTE: the order below matters!
      %w{ preferred_name display_name title name path }.each do |w|
        if escape_html
          return eval("CGI.escapeHTML(item.#{w})") if item.respond_to?(w)
          return CGI.escapeHTML(item[w]) if item.is_a?(Hash) && item.has_key?(w)
        else
          return eval("item.#{w}") if item.respond_to?(w)
          return item[w] if item.is_a?(Hash) && item.has_key?(w)
        end
      end
      return "#{item.class.name}_#{item.id}"  
    end
    
    # Given a set of params, this attempts to find the *single* object referred to.
    # Returns: obj_to_redirect_to (nil indicates nothing is found)
    #
    # TODO: optimise this! Right now it does a cascade find, but instead it should just
    # do one query and that's it.
    def self.lookup(params)
      obj_to_redirect_to = nil
      
      if params[:wsdl_location]
        wsdl_url = params[:wsdl_location] || ""
        wsdl_url = Addressable::URI.parse(wsdl_url).normalize.to_s unless wsdl_url.blank?
        
        unless wsdl_url.blank?
          soap_service = SoapService.find_by_wsdl_location(wsdl_url)
          
          if soap_service 
            
            if params[:operation_name]
              soap_operation = SoapOperation.find(:first, :conditions => { :soap_service_id => soap_service.id, :name => params[:operation_name] })
              
              if soap_operation
                
                if params[:input_name]
                  obj_to_redirect_to = SoapInput.find(:first, :conditions => { :soap_operation_id => soap_operation.id, :name => params[:input_name] })
                elsif params[:output_name]
                  obj_to_redirect_to = SoapOutput.find(:first, :conditions => { :soap_operation_id => soap_operation.id, :name => params[:output_name] })
                else
                  obj_to_redirect_to = soap_operation
                end
                
              end
            else
              obj_to_redirect_to = soap_service
            end
            
          end
        end
        
      end
      
      return obj_to_redirect_to
    end
    
    # Based on: http://stackoverflow.com/questions/1103327/how-to-uniq-an-array-case-insensitive/1103344#1103344
    def self.uniq_strings_case_insensitive(strings)
      downcased = [] 
      strings.inject([]) { |result,h| 
        unless downcased.include?(h.downcase);
          result << h
          downcased << h.downcase
        end;
        result 
      }
    end
    
    # type should be either:
    #   :error
    #   :warning
    #   :info
    def self.log_exception(ex, type, initial_msg="An exception occurred!")
      msg = initial_msg + "\n\tException type: #{ex.class.name}. \n\tException message: #{ex.message}. \n\t#{ex.backtrace.join("\n")}"
      case type
        when :error
          Util.yell(msg)
        when :warning
          Util.warn(msg)
        else
          Util.say(msg)
      end
    end
    
    # This generates a url template string which can be used to show how a REST Endpoint can be used.
    def self.generate_rest_endpoint_url_template(rest_method) 
      return '' if rest_method.blank?

      base_url = rest_method.associated_service_base_url.sub(/\/$/, '') # remove trailing '/' from base url
      resource_path = rest_method.rest_resource.path.sub(/^\/\?/, '?') # change "/?" to "?"
      resource_path.sub!(/^\/\&/, '&') # change "/&" to "&"
            
      required_params = []
      rest_method.request_parameters.select { |p| p.param_style=="query" && p.required }.each do |p|
        required_params << "#{p.name}={#{p.name}}"
      end
      
      required_params = required_params.join('&')
      required_params = '?' + required_params unless required_params.blank?

      url_template = (if base_url.include?('?') # base url has non configurable query params
                        required_params.gsub!('?', '&')
                        resource_path.gsub!('?', '&')
                        
                        if resource_path == '/{parameters}' 
                          "#{base_url}#{required_params}"
                        elsif resource_path.start_with?('/')
                          "Could not generate URL template"
                        else
                          "#{base_url}#{resource_path}#{required_params}"
                        end
                      else # base url does not have query params
                        if resource_path == '/{parameters}' 
                          "#{base_url}#{required_params}"
                        elsif resource_path == '/{id}'
                          "#{base_url}/{id}#{required_params}"
                        elsif resource_path.include?('?')
                          "#{base_url + resource_path}#{required_params.gsub('?', '&')}"
                        elsif resource_path.start_with?('&')
                          "#{base_url + resource_path.sub('&', '?')}#{required_params.gsub('?', '&')}"
                        else
                          "#{base_url + resource_path}#{required_params}"
                        end
                      end)

      # TODO: fix double slash bug in template
      # this is a temporary hack to remove "//" that appear in some templates.
      # i have not figure out exactly what is causing it, hence this dirty patch.
      url_template.squeeze!('/')
      url_template.sub!(':/', '://') # compensation of squeeze
      
      return url_template
    end

  end
end
