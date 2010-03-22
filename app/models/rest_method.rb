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

    # iterate and create objects
    extracted_param_count = 0
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
      param_value.gsub!('-', '_')
      param_value = "" if param_value =~ /\W/

      # next if param name contains non-alphanumeric characters
      next if param_name.gsub('-', '_') =~ /\W/
      
      begin
        transaction do
          extracted_param = RestParameter.check_exists_for_rest_service(self.rest_resource.rest_service, param_name, options[:make_local])

          if extracted_param.nil?
            extracted_param = RestParameter.new(:name => param_name, 
                                                :param_style => options[:param_style], 
                                                :default_value => param_value,
                                                :required => is_mandatory,
                                                :is_global => !options[:make_local])
            extracted_param.submitter = user_submitting
            extracted_param.save!
          end
          
          no_param_for_method = RestParameter.check_duplicate(self, param_name, options[:make_local]).nil?

          if no_param_for_method
            @method_param_map = RestMethodParameter.new(:rest_method_id => self.id,
                                                        :rest_parameter_id => extracted_param.id,
                                                        :http_cycle => "request")
            @method_param_map.submitter = user_submitting
            @method_param_map.save!
            
            extracted_param_count += 1
          end

          begin
            extracted_param.create_annotations({"example_data" => "#{param_name}=#{param_value}"}, user_submitting) unless param_value.empty?
          rescue Exception => ex
            logger.error("Failed to create annotations for RestParameter with ID: #{extracted_param.id}. Exception:")
            logger.error(ex.message)
            logger.error(ex.backtrace.join("\n"))
          end
          
        end # transaction
      rescue Exception => ex
        @method_param_map.destroy if @method_param_map
      end # begin_rescue
    end # params_list.each
    
    return extracted_param_count
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

    # iterate and create objects
    extracted_rep_count = 0
    content_types.split("\n").sort.each do |content_type| # params_list.each
      content_type.chomp!
      content_type.downcase!
      
      next if content_type.split('/').size != 2
      
      base_type, sub_type = content_type.split('/')
      next unless SUPPORTED_CONTENT_TYPES.include?(base_type)

      begin
        transaction do
          representation = RestRepresentation.check_exists_for_rest_service(self.rest_resource.rest_service, content_type)

          if representation.nil?
            representation = RestRepresentation.new(:content_type => content_type)
            representation.submitter = user_submitting
            representation.save!
          end
          
          no_representation = RestRepresentation.check_duplicate(self, content_type, options[:http_cycle]).nil?
          
          if no_representation
            @method_rep_map = RestMethodRepresentation.new(:rest_method_id => self.id,
                                                           :rest_representation_id => representation.id,
                                                           :http_cycle => options[:http_cycle])
            @method_rep_map.submitter = user_submitting
            @method_rep_map.save!
           
            extracted_rep_count += 1
         end
        end # transaction
      rescue Exception => ex
        @method_rep_map.destroy if @method_rep_map
      end # begin_rescue
    end
    
    return extracted_rep_count
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
