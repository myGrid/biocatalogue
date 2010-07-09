# BioCatalogue: app/models/rest_service.rb
#
# Copyright (c) 2009, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

class RestService < ActiveRecord::Base
  if ENABLE_CACHE_MONEY
    is_cached :repository => $cache
  end
  
  if ENABLE_TRASHING
    acts_as_trashable
  end
  
  acts_as_service_versionified  # This also mixes in acts_as_annotatable
  
  has_many :rest_resources,
           :dependent => :destroy,
           :include => [ :rest_methods, :parent_resource ]
  
  validates_presence_of :name
  
  validates_associated :rest_resources
  
  validates_url_format_of :interface_doc_url,
                          :allow_nil => true,
                          :message => 'is not valid'
                          
  validates_url_format_of :documentation_url,
                          :allow_nil => true,
                          :message => 'is not valid'

  has_many :url_monitors, 
           :as => :parent,
           :dependent => :destroy
           
  has_many :rest_resources,
           :dependent => :destroy

  if ENABLE_SEARCH
    acts_as_solr(:fields => [ :name, :description, :interface_doc_url, :documentation_url, :service_type_name,
                              { :associated_service_id => :r_id } ])
  end
  
  if USE_EVENT_LOG
    acts_as_activity_logged(:models => { :referenced => { :model => :service_version } })
  end
  
  
  # ======================================
  # Class level method stubs reimplemented
  # from acts_as_service_versionified
  # --------------------------------------
  
  def self.check_duplicate(endpoint)
    endpoint.sub!(/\/$/, '') # remove trailing '/' from endpoint
    
    obj = ServiceDeployment.find(:first, :conditions => { :endpoint => endpoint })
    obj = ServiceDeployment.find(:first, :conditions => { :endpoint => endpoint + '/' }) unless obj
          
    return (obj.nil? ? nil : obj.service)
  end
  
  # ======================================
  
  
  # =========================================
  # Instance level method stubs reimplemented
  # from acts_as_service_versionified
  # -----------------------------------------
  
  def service_type_name
    "REST"
  end
  
  def total_db_metadata_fields_count
    count = 0
    
    count += 1 unless self.description.blank?
    count += 1 unless self.documentation_url.blank?
    
    # TODO: get counts for resources, methods, parameters and representations.
    
    return count
  end
  
  # This method returns a count of all the annotations for this RestService and its child resources/methods/parameters/representations.
  def total_annotations_count(source_type)
    count = 0
    
    count += self.count_annotations_by(source_type)
    
    # TODO: get counts for resources, methods, parameters and representations.
    
    return count
  end
  
  # =========================================
  
  
  def submit_service(endpoint, actual_submitter, annotations_data, resource_data="")
    success = true
    
    begin
      transaction do
        self.save!
        self.perform_post_submit(endpoint, actual_submitter)
      end
    rescue Exception => ex
      #ActiveRecord::RecordNotSaved, ActiveRecord::RecordInvalid
      logger.error("Failed to submit REST service - #{endpoint}. Exception:")
      logger.error(ex.message)
      logger.error(ex.backtrace.join("\n"))
      success = false
    end  
    
    if success
      # process annotations
      begin
        self.process_annotations_data(annotations_data, actual_submitter)
      rescue Exception => ex
        logger.error("Failed to process annotations after REST service creation. REST service ID: #{self.id}. Exception:")
        logger.error(ex.message)
        logger.error(ex.backtrace.join("\n"))
      end
      
      # mine for resources from the give user input
      begin
        mine_for_resources(resource_data, endpoint, actual_submitter) unless resource_data.empty?
      rescue Exception => ex
        logger.error("Failed to mine for resources after REST service creation. REST service ID: #{self.id}. Exception:")
        logger.error(ex.message)
        logger.error(ex.backtrace.join("\n"))
      end
    end
    
    return success
  end
  
  # =========================================

  
  def mine_for_resources(capture_string, endpoint, user_submitting)
    # sanitize the user input
    capture_string.chomp!
    capture_string.strip!
    capture_string.squeeze!(" ")

    base_url = endpoint.sub(/\/$/, '') # remove trailing '/' from endpoint and copy into base_url
    endpoint.sub!(/\/$/, '') # remove trailing '/' from endpoint
    base_url.gsub!(/http(s*)\:\/\//i, '') # remove protocol from base
    
    # create a list of the resources and try to create the corresponding
    # RestResource, RestMethod, RestParameter, RestMethodParameter objects
    
    # these lists will be returned in the form of a hash
    @created_endpoints = []
    @updated_endpoints = []
    @error_endpoints = [] 
    
    resource_list = capture_string.split("\n")
    resource_list.each do |user_endpoint|
      @query_params, @template_params, @resource_path, @http_method = nil, nil, nil, nil
      annotation_value = ""
      
      if process_user_endpoint(user_endpoint, base_url, annotation_value)
        transaction do
          if create_endpoint(user_endpoint, user_submitting)
            begin # add example endpoint annotation
              annotation_value.gsub!('{', '')
              annotation_value.gsub!('}', '')
              
              @extracted_method.create_annotations({"example_endpoint" => "#{endpoint}#{annotation_value}"}, user_submitting) if @template_params.blank?
            rescue Exception => ex
              logger.error("Failed to create annotations for RestMethod with ID: #{@extracted_method.id}. Exception:")
              logger.error(ex.message)
              logger.error(ex.backtrace.join("\n"))
            end
            
            # add parameters
            @extracted_method.add_parameters(@template_params.join("\n"), user_submitting, 
                                                                         :mandatory => true, 
                                                                         :param_style => "template",
                                                                         :make_local => true)
        
            @extracted_method.add_parameters(@query_params.join("\n"), user_submitting,
                                                                      :mandatory => true, 
                                                                      :param_style => "query",
                                                                      :make_local => true)
          end # inner if (endpoint objects successfully created)
        end # transaction
      end # outer if (endpoint was successfully processed)
      
    end # resource_list.each
    
    self.rest_resources(true) # refresh the model
    
    return {:created => @created_endpoints.uniq, 
            :updated => @updated_endpoints.uniq, 
            :error => @error_endpoints.uniq,
            :last_endpoint => (@redirect_endpoint || @extracted_method)}
  end # mine_for_resources
  
  def group_all_rest_methods_from_rest_resources
    return [ ] if self.rest_resources.blank?
    
    methods = [ ]
    
    self.rest_resources.each do |res|
      methods.concat(res.rest_methods)
    end
    
    return RestMethod.group_rest_methods(methods)
  end
  
  def endpoint_group_names_suggestions(fragment, limit=nil)
    # NOTE: this query has only been tested to work with MySQL 5.0.x and 5.1.x
    sql = [ "SELECT rest_methods.group_name AS name
           FROM rest_methods 
           INNER JOIN rest_resources ON rest_methods.rest_resource_id = rest_resources.id 
           WHERE rest_resources.rest_service_id = ? AND rest_methods.group_name LIKE ?
           GROUP BY rest_methods.group_name 
           ORDER BY rest_methods.group_name ASC",
           self.id,
           "%#{fragment}%" ]
    
    # If limit has been provided then add that to query
    if !limit.nil? && limit.is_a?(Fixnum) && limit > 0
      sql[0] = sql[0] + " LIMIT #{limit}"
    end
    
    return ActiveRecord::Base.connection.select_all(ActiveRecord::Base.send(:sanitize_sql, sql))
  end


  # =========================================
  
  def to_json
    generate_json_and_make_inline(false)
  end 

  def to_inline_json
    generate_json_and_make_inline(true)
  end

protected
  
  def associated_service_id
    BioCatalogue::Mapper.map_compound_id_to_associated_model_object_id(BioCatalogue::Mapper.compound_id_for(self.class.name, self.id), "Service")
  end
  
  
  # =========================================
  
  
private
  
  def process_user_endpoint(user_endpoint, base_url, annotation_value)
    # remove the base endpoint so that we are left with the resource path only.
    # in the event that the protocol (http or https) is left, remove that too
    resource = user_endpoint.gsub(/http(s*)\:\/\//i, '')
    resource.gsub!(base_url, '')

    endpoint_components = resource.split(' ')
    @http_method = ""
    @resource_path = endpoint_components[-1]
    annotation_value << endpoint_components[-1] 
    
    if endpoint_components.size == 1
      @http_method = "GET"
    elsif endpoint_components.size == 2
      # skip if given HTTP method contains other values other than GET, PUT, POST, and DELETE
      if %w{ GET PUT POST DELETE }.include?(endpoint_components[0].upcase)
        @http_method = endpoint_components[0].upcase
      else 
        @error_endpoints << user_endpoint
        return false
      end
    else 
      @error_endpoints << user_endpoint
      return false      
    end
    
    # only work on resource_paths that start with a punctuation mark
    unless @resource_path =~ /^\W.+$/
      @error_endpoints << user_endpoint
      return false
    end

    case @resource_path.split('?').size
      when 1
        if @resource_path.split('?')[0].start_with?('/') # yes == a resource path
          @query_params = []
          @template_params = @resource_path.split('?')[0].split('{')
          @resource_path = @resource_path.split('?')[0].split('/')
        else # params only
          @template_params = []
          @query_params = @resource_path.split('?')[0].split('&')
          @resource_path = []
        end
      when 2
        @template_params, @query_params = @resource_path.split('?')
        @query_params = @query_params.split('&')
        @template_params = @template_params.split('{')
        @resource_path = @resource_path.split('?')[0].split('/')
      else
        @error_endpoints << user_endpoint
        return false
    end
    
    @template_params.each { |p| p.gsub!(/\}.*/, '') } # remove everything after '}' 
    
    # only keep the template params that have format: param || param_name || param-name
    @template_params.reject! { |p| !p.gsub('-', '_').match(/^\w+$/) } 

    @template_params.reject! { |x| x.blank? }
    @resource_path.reject! { |x| x.blank? }
    
    # get the query params that define the service
    # ie query params that have format: param_name=param_value
    base_url_params = @query_params.select { |x| x.match(/^\w+\=\w+$/) }
    
    # only keep the configurable params to the service
    # ie keep the query params that have format: param_name={anything}
    @query_params.reject! { |x| !x.match(/^\w+\=\{.+\}$/) }
          
    @resource_path = @resource_path.join('/')
    @resource_path ||= ""
    
    if !base_url_params.empty?
      @resource_path = @resource_path + '?' + base_url_params.join('&')
    end
          
    @resource_path = '/' + @resource_path
    @resource_path = "/{parameters}" if @resource_path == '/'
    
    return true
  end # process_user_endpoint
  
  # =========================================

  def create_endpoint(user_endpoint, user_submitting)
    begin # create endpoint
      @extracted_resource = RestResource.check_duplicate(self, @resource_path)
      
      if @extracted_resource.nil?
        @extracted_resource = RestResource.new(:rest_service_id => self.id, 
                                               :path => @resource_path)
        @extracted_resource.submitter = user_submitting
        @extracted_resource.save!
      end
      
      @extracted_method = RestMethod.check_duplicate(@extracted_resource, @http_method)
      
      if @extracted_method.nil? # create ENDPOINT
        @extracted_method = RestMethod.new(:rest_resource_id => @extracted_resource.id, 
                                           :method_type => @http_method)
        @extracted_method.submitter = user_submitting
        @extracted_method.save!
        
        @redirect_endpoint = @extracted_method
        @created_endpoints << @extracted_method.display_endpoint
      else # update existing
        @updated_endpoints << @extracted_method.display_endpoint
      end
    rescue Exception => ex
      # no need to proceed with iteration since params will not have a resource object to attach to
      @error_endpoints << user_endpoint
      return false
    end # begin_rescue
    
    return true
  end # create_endpoint_objects
  
  # =========================================

  def generate_json_and_make_inline(make_inline)
    data = {
      "rest_service" => {
        "self" => BioCatalogue::Api.uri_for_object(self),
        "name" => BioCatalogue::Util.display_name(self),
        "submitter" => BioCatalogue::Api.uri_for_object(self.service_version.submitter),
        "description" => (self.description || ""),
        "documentation_url" => (self.preferred_documentation_url || ""),
        "created_at" => self.created_at.iso8601
      }
    }

    unless make_inline
      data["rest_service"]["deployments"] = BioCatalogue::JSON.collection(self.service_deployments, true)
    end
    
    return data.to_json
  end # generate_json_and_make_inline
  
end