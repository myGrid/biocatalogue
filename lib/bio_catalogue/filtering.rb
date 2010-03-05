# BioCatalogue: lib/bio_catalogue/filtering.rb
#
# Copyright (c) 2009-2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# Module for the core filtering functionality

module BioCatalogue
  
  module Filtering
    
    # ====================
    # Filtering URL format
    # --------------------

    # Filters are specified via the query parameters in URLs.
    # The general format for this is:
    #   ...?filter_type_1=[value1],[value2],[value3]&filter_type_2=[value4]&filter_type_3=[value5],[value6]&...

    # ====================
    
    
    UNKNOWN_TEXT = "(unknown)".freeze
    
    FILTER_KEYS = { :services => [ :cat, :t, :p, :su, :sr, :tag, :tag_s, :tag_ops, :tag_ins, :tag_outs, :c ],
                    :soap_operations => [ :tag, :tag_ops, :tag_ins, :tag_outs ],
                    :annotations => [ :attrib,
                                      :as, :asd, :asp, :ars, :ass, :asop, :asin, :asout,
                                      :soa, :sor, :sosp, :sou ] }.freeze
    
    ALL_FILTER_KEYS = FILTER_KEYS.values.flatten.uniq.freeze
    
    TAG_FILTER_KEYS = [ :tag, :tag_s, :tag_ops, :tag_ins, :tag_outs ].freeze
    
    FILTER_GROUPS = { :services => [ { "Service Categories" => [ :cat ] },
                                     { "Service Types" => [ :t ] },
                                     { "Service Providers" => [ :p ] },
                                     { "Submitters / Sources" => [ :su, :sr ] },
                                     { "Tags" => [ :tag ] },
                                     { "Tags (on Services)" => [ :tag_s ] },
                                     { "Tags (on Operations)" => [ :tag_ops ] },
                                     { "Tags (on Inputs)" => [ :tag_ins ] },
                                     { "Tags (on Outputs)" => [ :tag_outs ] },
                                     { "Locations" => [ :c ] } ],
                      :soap_operations => [ { "Tags" => [ :tag ] },
                                            { "Tags (on Operations)" => [ :tag_ops ] },
                                            { "Tags (on Inputs)" => [ :tag_ins ] },
                                            { "Tags (on Outputs)" => [ :tag_outs ] } ],
                      :annotations => [ { "Annotation Attributes" => [ :attrib ] },
                                        { "Annotatables" => [ :as, :asd, :asp, :ars, :ass, :asop, :asin, :asout ] },
                                        { "Sources" => [ :soa, :sor, :sosp, :sou ] } ] }.freeze
    
    FILTER_KEY_DISPLAY_NAMES = { :cat => "Service Categories",
                                   :t => "Service Types",
                                   :p => "Service Providers",
                                   :su => "Members",
                                   :sr => "Registries", 
                                   :tag => "Tags",
                                   :tag_s => "Tags (on Services)",
                                   :tag_ops => "Tags (on Operations)",
                                   :tag_ins => "Tags (on Inputs)",
                                   :tag_outs => "Tags (on Outputs)",
                                   :c => "Countries",
                                   :as => "Services",
                                   :asd => "Service Deployments",
                                   :asp => "Service Providers",
                                   :ars => "REST Services",
                                   :ass => "SOAP Services",
                                   :asop => "SOAP Operations",
                                   :asin => "SOAP Inputs",
                                   :asout => "SOAP Outputs",
                                   :soa => "Agents",
                                   :sor => "Registries",
                                   :sosp => "Service Providers",
                                   :sou => "Members",
                                   :attrib => "Annotation Attributes" }.freeze
  
  
    protected
    
    
    def self.hash_for_filter_keys_to_group_names(resource_type_sym)
      results = { }
      
      FILTER_GROUPS[resource_type_sym].each do |group| 
        group.each do |name, filter_keys|
          filter_keys.each do |k|
            results[k] = name
          end
        end
      end
      
      return results
    end
    
  end

  
  # This is done twice so that an intial one is created 
  # with some basic methods required by the rest here...
  module Filtering
    
    FILTER_GROUP_NAMES_FOR_KEYS = { :services => Filtering.hash_for_filter_keys_to_group_names(:services),
                                    :soap_operations => Filtering.hash_for_filter_keys_to_group_names(:soap_operations),
                                    :annotations => Filtering.hash_for_filter_keys_to_group_names(:annotations) }
    
    
    # ==========
    # Helper classes and methods to build and represent collections of Filter Groups where:
    # - A collection of filters for a particular resource type has 0 or more 'FilterGroup' objects
    # - A FilterGroup has 1 or more 'FilterType' objects
    # - A FilterType has 0 or more Filter hashes of the form e.g.: 
    #   { "id" => "78", "name" => "John", "count" => "181" }
    #   (the "count" is for the particular resource type).
    #
    # Then, the combination logic for combining any filters applied is (at a conceptual level):
    # - All Filter criteria within a FilterType are OR'ed
    # - All FilterType within a FilterGroup are OR'ed too
    # - All FilterGroup are AND'ed
    # ==========

    class FilterGroup < Struct.new(:name, :filter_types); end
      
    class FilterType < Struct.new(:key, :name, :description, :filters); end
    
    # This gets an array of all the FilterGroups (with underlying FilterTypes and filters) for a particular resource type.
    #
    # 'resource_type' MUST either be:
    # - a string representing the camelized resource type. E.g.: "Services" or "SoapOperations". OR,
    # - a symbol representing the underscored resource type. E.g.: :services or :soap_operations
    def self.get_all_filter_groups_for(resource_type, limit_for_each_type=nil)
      return [ ] if resource_type.blank? 
      
      results = [ ]
      
      resource_type_normalised = normalise_resource_type(resource_type)
      
      FILTER_GROUPS[resource_type_normalised].each do |group| 
        group.each do |name, filter_keys|
          new_group = FilterGroup.new(name, [ ])
          filter_keys.each do |k|
            new_group.filter_types << FilterType.new(k, FILTER_KEY_DISPLAY_NAMES[k], "", eval("Filtering::#{resource_type.to_s.camelize}.get_filters_for_filter_type(k, limit_for_each_type)"))
          end
          results << new_group
        end
      end
      
      return results
    end
    
    # Takes a hash of filters, of the form: { filter_key => [ ids_of_filters ] }
    # e.g.: { :t => [ "SOAP" ], :p => [ "67", "23" ], :c => [ "USA", "(unknown)" ] }
    # ... and groups these and returns an array of the relevant FilterGroups (with underlying FilterTypes and filters).
    #
    # 'resource_type' MUST either be:
    # - a string representing the camelized resource type. E.g.: "Services" or "SoapOperations". OR,
    # - a symbol representing the underscored resource type. E.g.: :services or :soap_operations
    def self.filter_groups_from(filters, resource_type)
      return [ ] if filters.blank? or resource_type.blank?
      
      results = [ ]
      
      resource_type_normalised = normalise_resource_type(resource_type)
      
      # First convert to a Hash format that is better suited here...
      filters_in_grouped_hash = { }
      filters.each do |key, ids|
        group_name = FILTER_GROUP_NAMES_FOR_KEYS[resource_type_normalised][key]
        if filters_in_grouped_hash.has_key? group_name
          filters_in_grouped_hash[group_name] << { key => ids }
        else
          filters_in_grouped_hash[group_name] = [ { key => ids } ]
        end
      end
      
      # Now create the relevant FilterGroup etc objects...
      filters_in_grouped_hash.each do |group_name, filter_types|
        new_group = FilterGroup.new(group_name, [ ])
        
        filter_types.each do |filter_type|
          filter_type.each do |key, ids|
            new_group.filter_types << FilterType.new(key, FILTER_KEY_DISPLAY_NAMES[key], "", ids.map { |id| { 'id' => id, 'name' => Filtering.display_name_for_filter(key, id) } })
          end
        end
        results << new_group
      end
      
      return results
    end
    
    # ==========
    
    
    def self.filter_type_to_display_name(filter_type)
      FILTER_KEY_DISPLAY_NAMES[filter_type.to_sym] || "(unknown)"
    end
    
    def self.display_name_for_filter(filter_type, filter_id)
      name = filter_id
      
      unless [ :t, :tag, :tag_s, :tag_ops, :tag_ins, :tag_outs, :c ].include?(filter_type)
        name = case filter_type
          when :cat
            c = Category.find_by_id(filter_id)
            (c.nil? ? "(unknown category)" : c.name)
          when :p, :asp, :sosp
            s = ServiceProvider.find_by_id(filter_id)
            (s.nil? ? "(unknown provider)" : BioCatalogue::Util.display_name(s, false))
          when :su, :sou
            u = User.find_by_id(filter_id)
            (u.nil? ? "(unknown user)" : BioCatalogue::Util.display_name(u, false))
          when :sr, :sor
            r = Registry.find_by_id(filter_id)
            (r.nil? ? "(unknown registry)" : BioCatalogue::Util.display_name(r, false))
          when :soa
            a = Agent.find_by_id(filter_id)
            (a.nil? ? "(unknown agent)" : BioCatalogue::Util.display_name(a, false))
          when :attrib
            a = AnnotationAttribute.find_by_id(filter_id)
            (a.nil? ? "(unknown annotation attribute)" : a.identifier)
          when :as
            a = Service.find_by_id(filter_id)
            (a.nil? ? "(unknown service)" : BioCatalogue::Util.display_name(a, false))
          when :asd
            a = ServiceDeployment.find_by_id(filter_id)
            (a.nil? ? "(unknown service deployment)" : "Service Deployment #{a.id}")
          when :ars
            a = RestService.find_by_id(filter_id)
            (a.nil? ? "(unknown REST service)" : BioCatalogue::Util.display_name(a, false))
          when :ass
            a = SoapService.find_by_id(filter_id)
            (a.nil? ? "(unknown SOAP service)" : BioCatalogue::Util.display_name(a, false))
          when :asop
            a = SoapOperation.find_by_id(filter_id)
            (a.nil? ? "(unknown SOAP operation)" : BioCatalogue::Util.display_name(a, false))
          when :asin
            a = SoapInput.find_by_id(filter_id)
            (a.nil? ? "(unknown SOAP input)" : BioCatalogue::Util.display_name(a, false))
          when :asout
            a = SoapOperation.find_by_id(filter_id)
            (a.nil? ? "(unknown SOAP output)" : BioCatalogue::Util.display_name(a, false))
        end
      end
      
      return name
    end
    
    # Returns nil if no filters are present
    def self.filters_text_if_filters_present(filters)
      if filters.blank?
        return nil
      else
        if filters.keys.length == 1
          filters.each do |k,v|
            filter_type_text = filter_type_to_display_name(k)
            filter_type_text = filter_type_text.singularize if v.length == 1
            return "Filtered by #{filter_type_text}: #{v.map { |s| display_name_for_filter(k, s) }.to_sentence}"
          end
        else
          return "Filtered by multiple criteria"
        end
      end
    end
    
    # Returns back a cloned params object with the new filter specified within it.
    def self.add_filter_to_params(params, filter_type, filter_value)
      params_dup = BioCatalogue::Util.duplicate_params(params)
    
      if params_dup[filter_type].blank?
        params_dup[filter_type] = "[#{filter_value}]"
      else
        params_dup[filter_type] << ",[#{filter_value}]"
      end
      
      # Reset page param
      params_dup.delete(:page)
      
      return params_dup
    end
    
    # Returns back a cloned params object with the filter specified removed from it.
    def self.remove_filter_from_params(params, filter_type, filter_value)
      params_dup = BioCatalogue::Util.duplicate_params(params)
    
      unless params_dup[filter_type].blank?
        params_dup[filter_type].gsub!("[#{filter_value}],", "")
        params_dup[filter_type].gsub!(",[#{filter_value}]", "")
        params_dup[filter_type].gsub!("[#{filter_value}]", "")
      end
      
      params_dup.delete(filter_type) if params_dup[filter_type].blank?
      
      # Reset page param
      params_dup.delete(:page)
      
      return params_dup
    end
    
    def self.is_filter_selected(current_filters, filter_type, filter_value)
      return current_filters[filter_type] && current_filters[filter_type].include?(filter_value.to_s)
    end
    
    # Converts the params from a URL query string into a more structured filters collection, where:
    # { filter_key => [ ids_of_filter_values ] }
    #
    # Example return value:
    #   { :t => [ "SOAP" ], :p => [ "67", "23" ], :c => [ "USA", "(unknown)" ] }
    #
    # Note: irrelevant query parameters will be ignored and left untouched.
    def self.convert_params_to_filters(params, scope=:services)
      filters = { }
      
      params.each do |key, values|
        key_sym = key.to_s.to_sym
        filters[key_sym] = self.split_filter_options_string(values) if FILTER_KEYS[scope].include?(key_sym)
      end
      
      Rails.logger.info "*** convert_params_to_filters returned #{filters.inspect}"
      
      return filters
    end
    
    # Remember the query format (mentioned above):
    # ...?filter_type_1=[value1],[value2],[value3]&filter_type_2=[value4]&filter_type_3=[value5],[value6]&...
    #
    # This method splits one set of values for one filter_type into an array of values.
    # ie: splits the string "[value1],[value2],[value3],...,[valuen]"
    def self.split_filter_options_string(filter_options)
      filter_options_splitted = filter_options.split("],[")
      
      # Now the first item will have a '[' at the beginning, and the last item will have a ']'...
      # NOTE: array[-1] refers to the last item in the Array.
      
      filter_options_splitted[0] = filter_options_splitted[0][1..-1]
      filter_options_splitted[-1] = filter_options_splitted[-1][0...-1] 
      
      return filter_options_splitted
    end
    
    # Converts a list of values (or one value) into a string that can be used as the value for a query parameter.
    def self.values_to_query_parameter_text(values)
      return "" if values.blank?
      
      text = ""
      
      values = [ values ].flatten
      
      values.each do |v|
        if text.blank?
          text = "[#{v}]"
        else
          text << ",[#{v}]"
        end
      end
      
      return text
    end
    
    # 'resource_type' MUST either be:
    # - a string representing the camelized resource type. E.g.: "Services" or "SoapOperations". OR,
    # - a symbol representing the underscored resource type. E.g.: :services or :soap_operations
    def self.normalise_resource_type(resource_type)
      case resource_type
        when String
          return resource_type.underscore.to_sym
        when Symbol
          return resource_type
        else
          raise ArgumentError, "resource_type is not a String or a Symbol! Value specified was: #{resource_type.inspect}", caller
      end
    end
    
  end
end