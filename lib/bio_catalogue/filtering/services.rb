# BioCatalogue: lib/bio_catalogue/filtering/services.rb
#
# Copyright (c) 2010-2011, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# Module for filtering specific to services

module BioCatalogue
  module Filtering
    module Services

      # ======================
      # Filter options finders
      # ----------------------
  
      def self.get_filters_for_filter_type(filter_type, limit=nil, search_query=nil)
        case filter_type
          when :cat
            get_filters_for_categories
          when :t
            get_filters_for_service_types(limit)
          when :p
            get_filters_for_service_providers(limit)
          when :su
            get_filters_for_submitters_users(limit)
          when :sr
            get_filters_for_submitters_registries(limit)
          when :tag
            get_filters_for_all_tags(limit)
          when :tag_s
            get_filters_for_service_tags(limit)
          when :tag_ops
            get_filters_for_soap_operation_tags(limit)
          when :tag_rms
            get_filters_for_rest_method_tags(limit)
          when :tag_ins
            get_filters_for_input_tags(limit)
          when :tag_outs
            get_filters_for_output_tags(limit)
          when :c
            get_filters_for_countries(limit)
          else
            [ ]
        end
      end
      
      # Gets an ordered list of the categories, as a tree of hashes.
      #
      # Example return data:
      # [ { "id" => "4", "name" => "x", "count" => "5", "children" => [ { "id" => "8", "name" => "xx", "count" => "4" }, { "id" => "10", "name" => "xy", "count" => "11" }, ... ] }, { "id" => "120", "name" => "y", "count" => "11", "children" => [ ] }, ... ]
      def self.get_filters_for_categories
        return build_categories_filters(Category.root_categories)
      end
      
      # Gets an ordered list of all the service providers and their counts of services.
      #
      # Example return data:
      # [ { "id" => "5", "name" => "EBI", "count" => "12" }, { "id" => "89", "name" => "example.com", "count" => "11" }, ... ]
      def self.get_filters_for_service_providers(limit=nil)
        # NOTE: this query has only been tested to work with MySQL 5.0.x
        sql = "SELECT service_providers.id AS id, service_providers.name AS name, COUNT(*) AS count 
              FROM service_providers 
              INNER JOIN service_deployments ON service_providers.id = service_deployments.service_provider_id 
              INNER JOIN services ON services.id = service_deployments.service_id 
              GROUP BY service_providers.id 
              ORDER BY COUNT(*) DESC"
        
        # If limit has been provided in the URL then add that to query.
        if !limit.nil? && limit.is_a?(Fixnum) && limit > 0
          sql += " LIMIT #{limit}"
        end
         
        return ActiveRecord::Base.connection.select_all(sql)
      end
      
      # Gets an ordered list of all the different service types and their counts of services.
      #
      # Example return data:
      # [ { "id" => "SOAP", "name" => "SOAP", "count" => "102" }, { "id" => "REST", "name" => "REST", "count" => "11" }, ... ]
      def self.get_filters_for_service_types(limit=nil)
        filters = { }
        
        # NOTE: this query has only been tested to work with MySQL 5.0.x
        sql = "SELECT service_versions.service_versionified_type AS name, COUNT(*) AS count 
              FROM service_versions 
              INNER JOIN services ON services.id = service_versions.service_id 
              GROUP BY service_versions.service_versionified_type 
              ORDER BY COUNT(*) DESC"
        
        # If limit has been provided in the URL then add that to query.
        if !limit.nil? && limit.is_a?(Fixnum) && limit > 0
          sql += " LIMIT #{limit}"
        end
         
        filters = ActiveRecord::Base.connection.select_all(sql)
        
        # Need to "massage" the returned data...
        
        filters.each do |f|
          t = f["name"].constantize.new.service_type_name
          f["name"] = t
          f["id"] = t
        end
        
        return filters
      end
      
      # Gets an ordered list of all the submitters that are Users and their counts of services.
      #
      # Example return data:
      # [ { "id" => "78", "name" => "John", "count" => "181" }, { "id" => "998", "name" => "Paula", "count" => "11" }  ... ]
      def self.get_filters_for_submitters_users(limit=nil)
        # NOTE: this query has only been tested to work with MySQL 5.0.x
        sql = "SELECT users.id AS id, users.display_name AS name, COUNT(*) AS count 
              FROM users 
              INNER JOIN services ON services.submitter_type = 'User' AND services.submitter_id = users.id 
              GROUP BY users.id
              ORDER BY COUNT(*) DESC"
        
        # If limit has been provided in the URL then add that to query.
        if !limit.nil? && limit.is_a?(Fixnum) && limit > 0
          sql += " LIMIT #{limit}"
        end
         
        return ActiveRecord::Base.connection.select_all(sql)
      end
      
      # Gets an ordered list of all the submitters that are Registries and their counts of services.
      #
      # Example return data:
      # [ { "id" => "73", "name" => "Feta", "count" => "181" }, { "id" => "3", "name" => "Seekda", "count" => "11" }  ... ]
      def self.get_filters_for_submitters_registries(limit=nil)
        # NOTE: this query has only been tested to work with MySQL 5.0.x
        sql = "SELECT registries.id AS id, registries.display_name AS name, COUNT(*) AS count 
              FROM registries 
              INNER JOIN services ON services.submitter_type = 'Registry' AND services.submitter_id = registries.id 
              GROUP BY registries.id
              ORDER BY COUNT(*) DESC"
        
        # If limit has been provided in the URL then add that to query.
        if !limit.nil? && limit.is_a?(Fixnum) && limit > 0
          sql += " LIMIT #{limit}"
        end
         
        return ActiveRecord::Base.connection.select_all(sql)
      end
      
      # Gets an ordered list of all the countries (the service deployments are in) and their counts of services.
      #
      # Example return data:
      # [ { "id" => England", "name" => "England", "count" => "18" }, { "id" => "Germany", "name" => "Germany", "count" => "5" }, { "id" => "(unknown), "name" => "(unknown)", "count" => "3" }  ... ]
      def self.get_filters_for_countries(limit=nil)
        # NOTE: this query has only been tested to work with MySQL 5.0.x
        sql = "SELECT service_deployments.country AS id, service_deployments.country AS name, COUNT(*) AS count 
              FROM service_deployments 
              INNER JOIN services ON services.id = service_deployments.service_id 
              GROUP BY service_deployments.country
              ORDER BY COUNT(*) DESC"
        
        # If limit has been provided in the URL then add that to query.
        if !limit.nil? && limit.is_a?(Fixnum) && limit > 0
          sql += " LIMIT #{limit}"
        end
         
        items = ActiveRecord::Base.connection.select_all(sql)
        
        # Need to replace the blank name with "(unknown)" (for services that don't have a country set)
        items.each do |item|
          if item['name'].blank?
            item['name'] = UNKNOWN_TEXT
            item['id'] = UNKNOWN_TEXT
          end
        end
        
        return items
      end
      
      # Gets an ordered list of all the tags on everything.
      #
      # Example return data:
      # [ { "id" => "blast", "name" => "blast", "count" => "500" }, { "id" => "bio", "name" => "bio", "count" => "110" }  ... ]
      def self.get_filters_for_all_tags(limit=nil)
        service_models = Mapper::SERVICE_STRUCTURE_MODELS.map{|m| m.to_s}
        get_filters_for_tags_by_service_models(service_models, limit, :all)
      end
      
      # Gets an ordered list of all the tags on Services, ServiceVersions, 
      # ServiceDeployments and any root service type Models (eg: SoapService).
      #
      # Example return data:
      # [ { "id" => "blast", "name" => "blast", "count" => "500" }, { "id" => "bio", "name" => "bio", "count" => "110" }  ... ]
      def self.get_filters_for_service_tags(limit=nil)
        service_models = [ "Service", "ServiceVersion", "ServiceDeployment" ] + Mapper::SERVICE_TYPE_ROOT_MODELS.map{|m| m.to_s}
        get_filters_for_tags_by_service_models(service_models, limit)
      end
      
      # Gets an ordered list of all the tags on SoapOperations.
      #
      # Example return data:
      # [ { "id" => "blast", "name" => "blast", "count" => "500" }, { "id" => "bio", "name" => "bio", "count" => "110" }  ... ]
      def self.get_filters_for_soap_operation_tags(limit=nil)
        get_filters_for_tags_by_service_models([ "SoapOperation" ], limit)
      end

      # Gets an ordered list of all the tags on RestMethods.
      #
      # Example return data:
      # [ { "id" => "blast", "name" => "blast", "count" => "500" }, { "id" => "bio", "name" => "bio", "count" => "110" }  ... ]
      def self.get_filters_for_rest_method_tags(limit=nil)
        get_filters_for_tags_by_service_models([ "RestMethod" ], limit)
      end
      
      # Gets an ordered list of all the tags on SoapInputs, RestParameters, and RestRepresentations.
      #
      # Example return data:
      # [ { "id" => "blast", "name" => "blast", "count" => "500" }, { "id" => "bio", "name" => "bio", "count" => "110" }  ... ]
      def self.get_filters_for_input_tags(limit=nil)
        get_filters_for_tags_by_service_models([ "SoapInput", "RestParameter", "RestRepresentation" ], limit, :request)
      end
      
      # Gets an ordered list of all the tags on SoapOutputs, RestParameters, and RestRepresentations.
      #
      # Example return data:
      # [ { "id" => "blast", "name" => "blast", "count" => "500" }, { "id" => "bio", "name" => "bio", "count" => "110" }  ... ]
      def self.get_filters_for_output_tags(limit=nil)
        get_filters_for_tags_by_service_models([ "SoapOutput", "RestParameter", "RestRepresentation" ], limit, :response)
      end
      
      # ======================
      
      
      # Returns:
      #   [ conditions, joins ] for use in an ActiveRecord .find method (or .paginate).
      def self.generate_conditions_and_joins_from_filters(filters, search_query=nil)
        conditions = { }
        joins = [ ]
        
        return [ conditions, joins ] if filters.blank? && search_query.blank?
        
        # Replace the unknown filter with nil
        filters.each do |k,v|
          v.each do |f|
            if f == UNKNOWN_TEXT
              v << nil
              v.delete(f)
            end
          end
        end
              
        # Now build the conditions and joins...
        
        service_ids_categories = [ ]
        service_ids_topics = [ ]
        service_ids_submitters = [ ]
        service_ids_all_tags = [ ]
        service_ids_tags_s = [ ]
        service_ids_tags_ops = [ ]
        service_ids_tags_rms = [ ]
        service_ids_tags_ins = [ ]
        service_ids_tags_outs = [ ]
        service_ids_search_query = [ ]
        
        unless filters.blank?
          filters.each do |filter_type, filter_values|
            unless filter_values.blank?
              case filter_type
                when :cat
                  service_ids_categories = get_service_ids_with_categories(filter_values)
                when :edam
                  service_ids_topics = get_service_ids_with_topics(filter_values)
                when :t
                  service_types = [ ]
                  filter_values.each do |f|
                    # TODO: strip this out into a more generic mapping table (prob in config or lib)
                    case f.downcase
                      when 'soap'
                        service_types << 'SoapService'
                      when 'rest'
                        service_types << 'RestService'
                    end
                  end
                  
                  unless service_types.blank?
                    conditions[:service_versions] = { :service_versionified_type => service_types }
                    joins << :service_versions
                  end
                when :p
                  providers = filter_values
                  
                  unless providers.blank?
                    conditions[:service_deployments] = { } if conditions[:service_deployments].blank?
                    conditions[:service_deployments][:service_provider_id] = providers
                    joins << [ { :service_deployments => :provider } ]
                  end
                when :c
                  countries = filter_values
                  
                  unless countries.blank?
                    conditions[:service_deployments] = { } if conditions[:service_deployments].blank?
                    conditions[:service_deployments][:country] = countries
                    joins << [ :service_deployments ]
                  end
                when :su
                  service_ids_submitters.concat(get_service_ids_with_submitter_users(filter_values))
                when :sr
                  service_ids_submitters.concat(get_service_ids_with_submitter_registries(filter_values))
                when :tag
                  service_models = Mapper::SERVICE_STRUCTURE_MODELS.map{|m| m.to_s}
                  service_ids_all_tags = get_service_ids_with_tag_on_service_models(service_models, filter_values, :all)
                when :tag_s
                  service_models = [ "Service", "ServiceVersion", "ServiceDeployment" ] + Mapper::SERVICE_TYPE_ROOT_MODELS.map{|m| m.to_s}
                  service_ids_tags_s = get_service_ids_with_tag_on_service_models(service_models, filter_values, :all)
                when :tag_ops
                  service_ids_tags_ops = get_service_ids_with_tag_on_service_models([ "SoapOperation" ], filter_values)
                when :tag_rms
                  service_ids_tags_rms = get_service_ids_with_tag_on_service_models([ "RestMethod" ], filter_values)
                when :tag_ins
                  service_ids_tags_ins = get_service_ids_with_tag_on_service_models([ "SoapInput", "RestRepresentation", "RestParameter" ], filter_values, :request)
                when :tag_outs
                  service_ids_tags_outs = get_service_ids_with_tag_on_service_models([ "SoapOutput", "RestRepresentation", "RestParameter" ], filter_values, :response)
              end
            end
          end
        end
        
        # Take into account search query if present
        unless search_query.blank?
          search_results = Search.sunspot_search(search_query, "services")
          unless search_results.blank?
            #service_ids_search_query = search_results.item_ids_for("services")
            service_ids_search_query = BioCatalogue::Search::Results::get_item_ids(search_results, 'services')
          end
        end
        
        # Need to go through the various service IDs found for the different criterion 
        # and add to the conditions collection (if common ones are found).
        # This ANDs the service IDs (ie: uses only the service IDs that match all criterion).
        
        # To carry out this process properly, we set a dummy value of 0 to any array that returned NO service IDs.
        service_ids_categories = [ 0 ] if service_ids_categories.empty? and filters.has_key?(:cat)
        service_ids_topics = [ 0 ] if service_ids_topics.empty? and filters.has_key?(:edam)
        service_ids_submitters = [ 0 ] if service_ids_submitters.empty? and (filters.has_key?(:su) or filters.has_key?(:sr))
        service_ids_all_tags = [ 0 ] if service_ids_all_tags.empty? and filters.has_key?(:tag)
        service_ids_tags_s = [ 0 ] if service_ids_tags_s.empty? and filters.has_key?(:tag_s)
        service_ids_tags_ops = [ 0 ] if service_ids_tags_ops.empty? and filters.has_key?(:tag_ops)
        service_ids_tags_rms = [ 0 ] if service_ids_tags_rms.empty? and filters.has_key?(:tag_rms)
        service_ids_tags_ins = [ 0 ] if service_ids_tags_ins.empty? and filters.has_key?(:tag_ins)
        service_ids_tags_outs = [ 0 ] if service_ids_tags_outs.empty? and filters.has_key?(:tag_outs)
        service_ids_search_query = [ 0 ] if service_ids_search_query.empty? and !search_query.blank?
        
#        Util.say "*** service_ids_categories = #{service_ids_categories.inspect}"
#        Util.say "*** service_ids_submitters = #{service_ids_submitters.inspect}"
#        Util.say "*** service_ids_all_tags = #{service_ids_all_tags.inspect}"
#        Util.say "*** service_ids_tags_s = #{service_ids_tags_s.inspect}"
#        Util.say "*** service_ids_tags_ops = #{service_ids_tags_ops.inspect}"
#        Util.say "*** service_ids_tags_rms = #{service_ids_tags_rms.inspect}"
#        Util.say "*** service_ids_tags_ins = #{service_ids_tags_ins.inspect}"
#        Util.say "*** service_ids_tags_outs = #{service_ids_tags_outs.inspect}"
#        Util.say "*** service_ids_search_query = #{service_ids_tags_outs.inspect}"
        
        service_id_arrays_to_process = [ ]
        service_id_arrays_to_process << service_ids_categories unless service_ids_categories.blank?
        service_id_arrays_to_process << service_ids_topics unless service_ids_topics.blank?
        service_id_arrays_to_process << service_ids_submitters unless service_ids_submitters.blank?
        service_id_arrays_to_process << service_ids_all_tags unless service_ids_all_tags.blank?
        service_id_arrays_to_process << service_ids_tags_s unless service_ids_tags_s.blank?
        service_id_arrays_to_process << service_ids_tags_ops unless service_ids_tags_ops.blank?
        service_id_arrays_to_process << service_ids_tags_rms unless service_ids_tags_rms.blank?
        service_id_arrays_to_process << service_ids_tags_ins unless service_ids_tags_ins.blank?
        service_id_arrays_to_process << service_ids_tags_outs unless service_ids_tags_outs.blank?
        service_id_arrays_to_process << service_ids_search_query unless service_ids_search_query.blank?
   
        final_service_ids = nil
        
        service_id_arrays_to_process.each do |a|
          if final_service_ids.nil?
            final_service_ids = a
          else
            final_service_ids = (final_service_ids & a)
          end
        end
        
#        Util.say "*** final_service_ids (after combining service id arrays) = #{final_service_ids.inspect}"
        
        unless final_service_ids.nil?
          # Remove the dummy value of 0 in case it is in there
          final_service_ids.delete(0)
          
          # If filter(s) / query were specified but nothing was found that means we have an empty result set
          final_service_ids = [ -1 ] if final_service_ids.blank? and 
                                        (filters.has_key?(:cat) or
                                         filters.has_key?(:edam) or
                                         filters.has_key?(:su) or 
                                         filters.has_key?(:sr) or 
                                         filters.has_key?(:tag) or
                                         filters.has_key?(:tag_s) or
                                         filters.has_key?(:tag_ops) or 
                                         filters.has_key?(:tag_rms) or 
                                         filters.has_key?(:tag_ins) or 
                                         filters.has_key?(:tag_outs) or 
                                         !search_query.blank?)
          
#          Util.say "*** final_service_ids (after cleanup) = #{final_service_ids.inspect}"
          
          conditions[:id] = final_service_ids unless final_service_ids.blank?
        end
        
        return [ conditions, joins ]
      end
    
      
    protected
      
      
      def self.build_categories_filters(categories)
        return [ ] if categories.blank?
        
        filters_list = [ ]
        
        categories.each do |category|
        
          filter = { }
          filter['id'] = category.id.to_s
          filter['name'] = category.name
          filter['count'] = BioCatalogue::Categorising.number_of_services_for_category(category)
          filter['children'] = [ ]
          
          if category.has_children?
            filter['children'] = build_categories_filters(category.children)
          end
          
          filters_list << filter
          
        end
        
        return filters_list
      end
      
      # Gets an ordered list of all the tags on a particular set of models.
      # The counts that are returned reflect the number of services that match 
      # (taking into account mapping of service substructure objects to the parent service).
      # 
      # Example return data:
      # [ { "id" => "bio", "name" => "blast", "count" => "500" }, { "id" => "bio", "name" => "bio", "count" => "110" }  ... ]
      def self.get_filters_for_tags_by_service_models(model_names, limit=nil, http_cycle=nil)
        sql = [
          "SELECT tags.name AS name, annotations.annotatable_id AS id, annotations.annotatable_type AS type
          FROM annotations 
          INNER JOIN annotation_attributes ON annotations.attribute_id = annotation_attributes.id
          INNER JOIN tags ON tags.id = annotations.value_id AND annotations.value_type = 'Tag'
          WHERE annotation_attributes.name = 'tag' AND annotations.annotatable_type IN (?)",
          model_names 
        ]
        
        # If limit has been provided in the URL then add that to query.
        #
        # FIXME: limit specified here isn't actually the limit on how many
        # filters are returned. Rather, the amount of data fetched from the 
        # db to process. 
        if !limit.nil? && limit.is_a?(Fixnum) && limit > 0
          sql[0] = sql[0] + " LIMIT #{limit}"
        end
        
        items = Annotation.connection.select_all(Annotation.send(:sanitize_sql, sql))
        
        # Group these tags and find out how many services match.
        # NOTE: MUST take into account that multiple service substructure objects could belong to the same Service, AND
        # take into account tags with different case (must treat them in a case-insensitive way).
        
        grouped_tags = { }
        
        items.each do |item|
          next unless BioCatalogue::Util.validate_as_rest_input_output_else_true(item, http_cycle)

          found = false
          
          tag_name = item['name']
          
          grouped_tags.each do |k,v|
            if k.downcase == tag_name.downcase
              found = true
              grouped_tags[k] << BioCatalogue::Mapper.compound_id_for(item['type'], item['id'])
            end
          end
          
          unless found
            grouped_tags[tag_name] = [ ] if grouped_tags[tag_name].nil?
            grouped_tags[tag_name] << BioCatalogue::Mapper.compound_id_for(item['type'], item['id'])
          end
            
        end
        
        filters = [ ]
        
        grouped_tags.each do |tag_name, op_ids|
          service_ids = BioCatalogue::Mapper.process_compound_ids_to_associated_model_object_ids(op_ids, "Service")
          service_ids = service_ids.compact.uniq
          filters << { 
            'id' => tag_name, 
            'name' => BioCatalogue::Tags.split_ontology_term_uri(tag_name).last,
            'count' => service_ids.length.to_s 
          }
        end
        
        filters.sort! { |a,b| b['count'].to_i <=> a['count'].to_i }
        
        return filters
      end
      
      def self.get_service_ids_with_categories(categories)
        results = [ ]
        
        categories.map{|c| c.to_i}.each do |c_id|
          results.concat(Categorising.get_service_ids_with_category(c_id))
        end
        
        return results
      end

      def self.get_service_ids_with_topics(topic_ids)
        results = []

        topic_ids.map{|topics| topics.to_i}.each do |annotation_id|
          results.concat([Annotation.find(annotation_id).annotatable.id])
          #results.concat([Annotation.find_annotatables_with_attribute_name_and_value('edam_topic', ann_text)])
        end
        return results
      end
      
      def self.get_service_ids_with_submitter_users(user_display_names)
        # NOTE: this query has only been tested to work with MySQL 5.0.x
        sql = [ "SELECT services.id
                FROM services 
                INNER JOIN users ON services.submitter_type = 'User' AND services.submitter_id = users.id 
                WHERE users.id IN (?)",
                user_display_names ]
        
        results = Service.connection.select_all(Service.send(:sanitize_sql, sql))
        
        return results.map{|r| r['id'].to_i}.uniq
      end
      
      def self.get_service_ids_with_submitter_registries(registry_display_names)
        # NOTE: this query has only been tested to work with MySQL 5.0.x
        sql = [ "SELECT services.id
                FROM services 
                INNER JOIN registries ON services.submitter_type = 'Registry' AND services.submitter_id = registries.id 
                WHERE registries.id IN (?)",
                registry_display_names ]
        
        results = Service.connection.select_all(Service.send(:sanitize_sql, sql))
        
        return results.map{|r| r['id'].to_i}.uniq
      end
      
      def self.get_service_ids_with_tag_on_service_models(model_names, tag_values, http_cycle=nil)
        sql = [ 
          "SELECT annotations.annotatable_id AS id, annotations.annotatable_type AS type
          FROM annotations 
          INNER JOIN annotation_attributes ON annotations.attribute_id = annotation_attributes.id
          INNER JOIN tags ON tags.id = annotations.value_id AND annotations.value_type = 'Tag'
          WHERE annotation_attributes.name = 'tag' AND annotations.annotatable_type IN (?) AND tags.name IN (?)",
          model_names,
          tag_values 
        ]
        
        results = Annotation.connection.select_all(Annotation.send(:sanitize_sql, sql))
        results.reject! { |item| !BioCatalogue::Util.validate_as_rest_input_output_else_true(item, http_cycle) }        

        return BioCatalogue::Mapper.process_compound_ids_to_associated_model_object_ids(results.map{|r| BioCatalogue::Mapper.compound_id_for(r['type'], r['id']) }, "Service").uniq     
      end
        
    end
  end
end