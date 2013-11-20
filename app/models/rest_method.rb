# BioCatalogue: app/models/rest_method.rb
#
# Copyright (c) 2009-2010, University of Manchester, The European Bioinformatics
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

class RestMethod < ActiveRecord::Base
  include RestServicesHelper #to access RestMethod template for as_csv export

  if ENABLE_CACHE_MONEY
    is_cached :repository => $cache
    index :rest_resource_id
    index [ :rest_resource_id, :method_type ]
    index [ :submitter_type, :submitter_id ]
  end
  
  # See http://www.iana.org/assignments/media-types/ for more information.
  SUPPORTED_CONTENT_TYPES = %w{ application audio example image message model multipart text video }.freeze

  SUPPORTED_HTTP_METHODS = [ 'OPTIONS', 'GET', 'HEAD', 'POST', 'PUT', 'DELETE', 'TRACE', 'CONNECT' ].freeze
  
  has_submitter
  
  validates_existence_of :submitter # User must exist in the db beforehand.

  if ENABLE_TRASHING
    acts_as_trashable
  end
  
  acts_as_archived
  
  acts_as_annotatable :name_field => :endpoint_name
  
  validates_presence_of :rest_resource_id, 
                        :method_type
  
  belongs_to :rest_resource
  
  has_one :rest_service, 
          :through => :rest_resource
  
  # =====================
  # Associated Parameters
  # ---------------------
  
  # Avoid using this association directly. 
  # Use the specific ones defined below.
  has_many :rest_method_parameters,
           :dependent => :destroy
  
  has_many :request_parameters,
           :through => :rest_method_parameters,
           :source => :rest_parameter,
           :class_name => "RestParameter",
           :conditions => [ "rest_method_parameters.http_cycle = ? AND rest_parameters.archived_at IS NULL", "request" ]
  
  has_many :response_parameters,
           :through => :rest_method_parameters,
           :source => :rest_parameter,
           :class_name => "RestParameter",
           :conditions => [ "rest_method_parameters.http_cycle = ? AND rest_parameters.archived_at IS NULL", "response" ]
           
  # =====================
  
  
  # ==========================
  # Associated Representations
  # --------------------------
  
  # Avoid using this association directly. 
  # Use the specific ones defined below.
  has_many :rest_method_representations,
           :dependent => :destroy
  
  has_many :request_representations,
           :through => :rest_method_representations,
           :source => :rest_representation,
           :class_name => "RestRepresentation",
           :conditions => [ "rest_method_representations.http_cycle = ? AND rest_representations.archived_at IS NULL", "request" ]
  
  has_many :response_representations,
           :through => :rest_method_representations,
           :source => :rest_representation,
           :class_name => "RestRepresentation",
           :conditions => [ "rest_method_representations.http_cycle = ? AND rest_representations.archived_at IS NULL", "response" ]
  
  # ==========================
  
  
  if ENABLE_SEARCH
    searchable do
       text :endpoint_name, :group_name, :display_endpoint, :method_type,
            :submitter_name, :rest_resource_search_terms, :description
    end
  end
  
  if USE_EVENT_LOG
    acts_as_activity_logged(:models => {:referenced => { :model => :rest_resource },
                                        :culprit => { :model => :submitter } })
  end
  
  # For the given 'rest_resource', find duplicate entry based on 'method_type'
  def self.check_duplicate(rest_resource, method_type)
    return rest_resource.rest_methods(true).find_by_method_type(method_type) # RestMethod || nil
  end
  
  def to_json
    generate_json_with_collections("default")
  end 
  
  def to_inline_json
    generate_json_with_collections(nil, true)
  end
  
  def to_custom_json(collections)
    generate_json_with_collections(collections)
  end
  
  # Check that an endpoint name does not exist in the parent service
  def check_endpoint_name_exists(name)
    rest_service = self.rest_resource.rest_service
    
    name_exists = false
    
    rest_service.rest_resources.each do |resource|
      resource.rest_methods.each { |m|
        name_exists = true if m.endpoint_name == name
        break if name_exists
      }
      break if name_exists
    end
    
    return name_exists
  end
  
  # used by activity feed
  def display_name 
    return (self.endpoint_name.blank? ? display_endpoint : self.endpoint_name)
  end
  
  # shows the endpoint value for self
  def display_endpoint
    return "#{self.method_type} #{self.rest_resource.path}"
  end

  def as_csv
    service_id =  self.associated_service.unique_code
    endpoint_name = self.endpoint_name
    template = create_url_template(self)
    method_type = self.method_type
    description = self.preferred_description
    submitter = self.submitter.display_name
    documentation_url = self.documentation_url
    annotations = self.get_service_tags
    return [service_id,endpoint_name,template,method_type,description,submitter,documentation_url,annotations]
  end


  def get_service_tags
    list = []
    BioCatalogue::Annotations.get_tag_annotations_for_annotatable(self).each { |ann| list << ann.value_content }
    return list.join("; ")
  end


  # for sort
  # TODO: need to figure out whether this is really necessary now, considering the new grouping functionality.
  def <=>(other)
    order = { 'GET' => 1, 'PUT' => 2, 'POST' => 3, 'DELETE' => 4, 
              'CONNECT' => 5, 'HEAD' => 6, 'OPTIONS' => 7, 'TRACE' => 8 }
    
    return order[self.method_type] <=> order[other.method_type]
  end
  
  # This returns an Array of Hashes that has the grouped (by group_name) 
  # and sorted RestMethods (from the ones provided).
  #
  # Example output:
  #   [ { :group_name => "..", :items => [ ... ] }, { :group_name => "..", :items => [ ... ] }  ]
  def self.group_rest_methods(methods)
    grouped = { }
    grouped_and_sorted = [ ]
        
    return grouped_and_sorted if methods.blank?
    
    methods.each do |m|
      group_name = (m.group_name.blank? ? "Other" : m.group_name)

      found = false
      
      grouped.each do |name, list|
        if name.downcase==group_name.downcase
          found = true
          list << m
        end
      end
      
      grouped[group_name] = [ m ] unless found
    end
    
    grouped.keys.sort.each do |k|
      grouped_and_sorted << { :group_name => k, :items => grouped[k].sort }
    end
    
    return grouped_and_sorted
  end
  

  # ==========================
  

  # This method adds RestParameters to this RestMethod.
  #
  # CONFIG OPTIONS
  #
  # :param_style - whether the parameter if of types: template, query, matrix, header
  #   default = "query"
  # :mandatory - specifies whether a parameter is mandatory/required or not by the endpoint
  #   default = false
  # :make_local - whether the parameters being added are meant to be made unique to this method 
  #   default = false
  def add_parameters(capture_string, user_submitting, *args)
    # TODO: MAKE CODE MODULAR!!!
    options = args.extract_options!
    options.reverse_merge!(:param_style => "query",
                           :mandatory => false,
                           :make_local => false)

    options[:param_style].downcase!

    return unless [true, false].include?(options[:mandatory])
    return unless [true, false].include?(options[:make_local])
    
    return unless %w{ template query matrix header }.include?(options[:param_style])
    
    # sanitize user input
    chomp_strip_squeeze(capture_string)
    
    # these lists will be returned in the form of a hash
    created_params = []
    updated_params = []
    error_params = [] 

    # iterate and create objects
    capture_string.split("\n").sort.each do |param| # params_list.each
      chomp_strip_squeeze(param)

      config_option = (param.split(' ').size==2 ? param.split(' ')[-1] : nil)
      is_mandatory = (if options[:mandatory]
                        true
                      elsif config_option=='!'
                        true
                      else
                        false
                      end)

      param.sub!(/\!$/, '') # sanitize ie remove '!' from the end of the string

      param_name, param_value = param.split('=')
      param_name.strip!
      param_value ||= ""
      param_value.strip!

      # sanitize ie get rid of special syntax
      param_name.gsub!('{', '')
      param_name.gsub!('}', '')
      
      param_value = nil if param_value.gsub('-', '_') =~ /\W/
      
      # next if param name contains non-alphanumeric characters
      if param_name.gsub('-', '_') =~ /\W/
        error_params << param_name
        next
      end

      begin
        transaction do
          extracted_param = RestParameter.check_duplicate(self, param_name, options[:make_local])
          no_param_for_method = extracted_param.nil?
          
          if no_param_for_method # create a new param
            extracted_param = RestParameter.new(:name => param_name, 
                                                :param_style => options[:param_style], 
                                                :required => is_mandatory,
                                                :is_global => !options[:make_local])
            extracted_param.submitter = user_submitting
            extracted_param.save!
            
            @method_param_map = RestMethodParameter.new(:rest_method_id => self.id,
                                                        :rest_parameter_id => extracted_param.id,
                                                        :http_cycle => "request")
            @method_param_map.submitter = user_submitting
            @method_param_map.save!

            created_params << param_name
          else # update existing param
            extracted_param.required = is_mandatory unless extracted_param.param_style=="template"
            extracted_param.save!

            updated_params << param_name
          end

          # add annotations
          begin
            extracted_param.create_annotations({"example_data" => "#{param_name}=#{param_value}"}, user_submitting) unless param_value.blank?
          rescue Exception => ex
            logger.error("Failed to create annotations for RestParameter with ID: #{extracted_param.id}. Exception:")
            logger.error(ex.message)
            logger.error(ex.backtrace.join("\n"))
          end
        end # transaction
      rescue Exception => ex
        @method_param_map.destroy if @method_param_map # TODO is this really necessary? is deletion not implicit on rollback?
        error_params << param_name
        
        logger.error("Failed to extract REST Parameters for RestMethod with ID #{self.id}. Exception:")
        logger.error(ex.message)
        logger.error(ex.backtrace.join("\n"))
      
        next
      end # begin_rescue
    end # params_list.each
    
    return {:created => created_params.uniq,
            :updated => updated_params.uniq, 
            :error => error_params.uniq}
  end
  
  
  # =========================================

  
  # This method adds RestRepresentations to this RestMethod.
  #
  # CONFIG OPTIONS
  #
  # :http_cycle - whether the representation is a request or a response representation
  #   default = "response"
  def add_representations(content_types, user_submitting, *args)
    # TODO: MAKE CODE MODULAR!!!
    options = args.extract_options!
    options.reverse_merge!(:http_cycle => "response")

    options[:http_cycle].downcase!
    return unless %w{ request response }.include?(options[:http_cycle])
    
    # sanitize user input
    chomp_strip_squeeze(content_types)

    # these lists will be returned in the form of a hash
    created_types = []
    updated_types = []
    error_types = [] 

    # iterate and create objects
    content_types.split("\n").sort.each do |content_type| # params_list.each
      content_type.chomp!
      content_type.downcase!
      
      if content_type.split('/').size != 2
        error_types << content_type
        next
      end
      
      base_type, sub_type = content_type.split('/')
      unless SUPPORTED_CONTENT_TYPES.include?(base_type)
        error_types << content_type
        next
      end

      begin
        transaction do
          representation = RestRepresentation.check_duplicate(self, content_type, options[:http_cycle])
          no_representation = representation.nil?
          
          if no_representation # create new representation
            representation = RestRepresentation.new(:content_type => content_type)
            representation.submitter = user_submitting
            representation.save!

            @method_rep_map = RestMethodRepresentation.new(:rest_method_id => self.id,
                                                           :rest_representation_id => representation.id,
                                                           :http_cycle => options[:http_cycle])
            @method_rep_map.submitter = user_submitting
            @method_rep_map.save!
           
            created_types << content_type
          else
            updated_types << content_type
          end
        end # transaction
      rescue Exception => ex
        @method_rep_map.destroy if @method_rep_map
        error_types << content_type
        next
      end # begin_rescue
    end
    
    return {:created => created_types.uniq,
            :updated => updated_types.uniq,
            :error => error_types.uniq}
  end
  
  def associated_service_id
    @associated_service_id ||= BioCatalogue::Mapper.map_compound_id_to_associated_model_object_id(BioCatalogue::Mapper.compound_id_for(self.class.name, self.id), "Service")
  end
  
  def associated_service
    @associated_service ||= Service.find_by_id(associated_service_id)
  end
  
  def associated_service_base_url
    @associated_service_base_url ||= (self.associated_service.blank? ? "" : self.associated_service.latest_deployment.endpoint) 
  end
  
  def preferred_description
    # Either the description from the service description doc, 
    # or the last description annotation.
    
    desc = self.description
    
    if desc.blank?
      desc = self.annotations_with_attribute("description", true).first.try(:value_content)
    end
    
    return desc
  end

  # =========================================

  
  # This method updates the resource path for this RestMethod's RestResource
  def update_resource_path(new_resource_path, user_submitting)
    # sanitize user input
    chomp_strip_squeeze(new_resource_path)
    new_resource_path.gsub!(' ', '+')
    
    return "Endpoint paths cannot be empty." if new_resource_path.blank?
    return "The new path is the same as the old one." if self.rest_resource.path==new_resource_path
    return "The new path contains one or more configurable query parameters (e.g. '...&name={value}')" if new_resource_path.match(/\w+\=\{.+\}/)
    
    # return "The new path contains invalid characters" if condition_here

    rest_service = self.rest_resource.rest_service
    return do_resource_path_update(rest_service, new_resource_path, user_submitting) # nil || error message
  end  
  
  
  # =========================================
  
protected
  
  def rest_resource_search_terms
    return "#{self.rest_resource.path} #{self.rest_resource.description}"
  end


  # ========================================
  
private
  
  def chomp_strip_squeeze(string)
    string.chomp!
    string.strip!
    string.squeeze!(" ")
  end # chomp strip squeeze
    
  # =========================================

  def do_resource_path_update(rest_service, new_resource_path, user_submitting)
    transaction do # do update
      begin 
        @new_resource = RestResource.check_duplicate(rest_service, new_resource_path)

        if @new_resource.nil?
          @new_resource = RestResource.new(:rest_service_id => rest_service.id, :path => new_resource_path)
          @new_resource.submitter = user_submitting
          @new_resource.save!
        end
            
        old_resource_id = self.rest_resource.id # needed for deletion if it is no longer used

        if RestMethod.check_duplicate(@new_resource, self.method_type).nil? # endpoint does not exist
          self.rest_resource_id = @new_resource.id
          self.save!
          
          old_res = RestResource.find(old_resource_id)
          old_res.destroy if old_res && old_res.rest_methods.blank? # remove unused RestResource
        else # endpoint exists 
          raise # complain that the endpoint already exists and return
        end
      rescue
        @new_resource.destroy if @new_resource
        return "Could not update the endpoint.  If this error persists we would be very grateful if you notified us."
      end
      
      # update template params
      template_params = new_resource_path.split("{")
      template_params.each { |p| p.gsub!(/\}.*/, '') } # remove everything after '}' 
  
      # only keep the template params that have format: param || param_name || param-name
      template_params.reject! { |p| !p.gsub('-', '_').match(/^\w+$/) } 
      template_params.reject! { |x| x.blank? }
      
      params_to_delete = self.request_parameters.select { |p| p.param_style=="template" && !template_params.include?(p.name) }
      params_to_delete.each { |p| p.destroy }
      
      self.request_parameters # reload collection
      
      self.add_parameters(template_params.join("\n"), user_submitting, 
                                                      :mandatory => true, 
                                                      :param_style => "template",
                                                      :make_local => true)
    end # transaction
    
    return nil
  end # do_resource_path_update
  
  # =========================================
  
  def generate_json_with_collections(collections, make_inline=false)
    collections ||= []

    allowed = %w{ input_parameters input_representations output_representations }
    
    if collections.class==String
      collections = case collections.strip.downcase
                      when "inputs"
                        %w{ inputs }
                      when "outputs"
                        %w{ outputs }
                      when "default"
                        %w{ inputs outputs }
                      else []
                    end
    else
      collections.each { |x| x.downcase! }
      collections.uniq!
      collections.reject! { |x| !allowed.include?(x) }
    end
        
    data = {
      "rest_method" => {
        "name" => self.endpoint_name,
        "endpoint_label" => self.display_endpoint,
        "http_method_type" => self.method_type,
        "url_template" => BioCatalogue::Util.generate_rest_endpoint_url_template(self),
        "submitter" => BioCatalogue::Api.uri_for_object(self.submitter),
        "description" => self.preferred_description,
        "documentation_url" => self.documentation_url,
        "created_at" => self.created_at.iso8601,
        "archived_at" => self.archived? ? self.archived_at.iso8601 : nil
      }
    }

    collections.each do |collection|
      case collection.downcase
        when "inputs"
          data["rest_method"]["inputs"] = {
            "parameters" => BioCatalogue::Api::Json.collection(self.request_parameters),
            "representations" => BioCatalogue::Api::Json.collection(self.request_representations)            
          }
        when "outputs"
          data["rest_method"]["outputs"] = {
            "parameters" => BioCatalogue::Api::Json.collection(self.response_parameters),
            "representations" => BioCatalogue::Api::Json.collection(self.response_representations)            
          }
      end
    end

    unless make_inline
      data["rest_method"]["self"] = BioCatalogue::Api.uri_for_object(self)
			return data.to_json
    else
      data["rest_method"]["resource"] = BioCatalogue::Api.uri_for_object(self)
			return data["rest_method"].to_json
    end
  end # generate_json_with_collections
  
end
