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
    
    def self.filter_type_to_display_name(filter_type)
      case filter_type
        when :cat
          "Service Categories"
        when :t
          "Service Types"
        when :p
          "Service Providers"
        when :su
          "Submitters (Members)"
        when :sr
          "Submitters (Registries)"
        when :tag
          "Tags"
        when :tag_s
          "Tags (on Services)"
        when :tag_ops
          "Tags (on Operations)"
        when :tag_ins
          "Tags (on Inputs)"
        when :tag_outs
          "Tags (on Outputs)"
        when :c
          "Countries"
        when :as
          "Annotatable Object - Services"
        when :asd 
          "Annotatable Object - Service Deployments"
        when :asp
          "Annotatable Object - Service Providers"
        when :ars
          "Annotatable Object - REST Services"
        when :ass
          "Annotatable Object - SOAP Services" 
        when :asop
          "Annotatable Object - SOAP Operations"
        when :asin
          "Annotatable Object - SOAP Inputs"
        when :asout
          "Annotatable Object - SOAP Outputs"
        when :soa
          "Source - Agents"
        when :sor
          "Source - Registries"
        when :sosp
          "Source - Service Providers" 
        when :sou
          "Source - Users"
        when :attrib
          "Annotation Attributes"
        else
          "(unknown)"
      end
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
    
  end
end