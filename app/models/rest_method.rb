# BioCatalogue: app/models/rest_method.rb
#
# Copyright (c) 2009, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

class RestMethod < ActiveRecord::Base
  if ENABLE_CACHE_MONEY
    is_cached :repository => $cache
    index :rest_resource_id
    index [ :rest_resource_id, :method_type ]
    index [ :submitter_type, :submitter_id ]
  end
  
  # See http://www.iana.org/assignments/media-types/ for more information.
  SUPPORTED_CONTENT_TYPES = %w{ application audio example image message model multipart text video }

  has_submitter
  
  validates_existence_of :submitter # User must exist in the db beforehand.

  acts_as_trashable
  
  acts_as_annotatable
  
  validates_presence_of :rest_resource_id, 
                        :method_type
  
  belongs_to :rest_resource
  
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
           :conditions => [ "rest_method_parameters.http_cycle = ?", "request" ]
  
  has_many :response_parameters,
           :through => :rest_method_parameters,
           :source => :rest_parameter,
           :class_name => "RestParameter",
           :conditions => [ "rest_method_parameters.http_cycle = ?", "response" ]
           
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
           :conditions => [ "rest_method_representations.http_cycle = ?", "request" ]
  
  has_many :response_representations,
           :through => :rest_method_representations,
           :source => :rest_representation,
           :class_name => "RestRepresentation",
           :conditions => [ "rest_method_representations.http_cycle = ?", "response" ]
  
  # ==========================
  
  
  if ENABLE_SEARCH
    acts_as_solr(:fields => [ :method_type, :description, :submitter_name, { :associated_service_id => :r_id } ])
  end
  
  if USE_EVENT_LOG
    acts_as_activity_logged(:models => {:referenced => { :model => :rest_resource },
                                        :culprit => { :model => :submitter } })
  end
  
  # For the given 'rest_resource', find duplicate entry based on 'method_type'
  def self.check_duplicate(rest_resource, method_type)
    return rest_resource.rest_methods(true).find_by_method_type(method_type) # RestMethod || nil
  end
  
  # used by activity feed
  def display_name 
    return (self.endpoint_name.blank? ? display_endpoint : self.endpoint_name)
  end
  
  # shows the endpoint value for self
  def display_endpoint
    return "#{self.method_type} #{self.rest_resource.path}"
  end
  
  # for sort
  def <=>(other)
    order = {'GET' => 1, 'POST' => 2, 'PUT' => 3, 'DELETE' => 4 }
    
    self_order = order[self.method_type]
    other_order = order[other.method_type]
    
    comparison = self_order <=> other_order
    return comparison unless comparison==0
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
      param_value.gsub!('{', '')
      param_value.gsub!('}', '')

      param_value = CGI::escape(param_value) unless param_value.blank?

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
                                                :default_value => param_value,
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
            extracted_param.default_value = param_value
            extracted_param.required = is_mandatory unless extracted_param.param_style=="template"
            extracted_param.save!

            updated_params << param_name
          end
        end # transaction
      rescue Exception => ex
        @method_param_map.destroy if @method_param_map
        error_params << param_name
        next
      end # begin_rescue
    end # params_list.each
    
    return {:created => created_params,
            :updated => updated_params, 
            :error => error_params}
  end

  # This method adds RestRepresentations to this RestMethod.
  #
  # CONFIG OPTIONS
  #
  # :http_cycle - whether the representation is a request or a response representation
  #   default = "response"
  def add_representations(content_types, user_submitting, *args)
    options = args.extract_options!
    options.reverse_merge!(:http_cycle => "response")

    options[:http_cycle].downcase!
    return unless %w{ request response }.include?(options[:http_cycle])
    
    # sanitize user input
    content_types.chomp!
    content_types.strip!
    content_types.squeeze!(" ")

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
    
    return {:created => created_types,
            :updated => updated_types,
            :error => error_types}
  end
  
  
  # =========================================
  
  
  protected
  
  def associated_service_id
    BioCatalogue::Mapper.map_compound_id_to_associated_model_object_id(BioCatalogue::Mapper.compound_id_for(self.class.name, self.id), "Service")
  end


  # ========================================
  
  
  private
  
  def chomp_strip_squeeze(string)
    string.chomp!
    string.strip!
    string.squeeze!(" ")
  end
end
