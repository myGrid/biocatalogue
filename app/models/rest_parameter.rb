# BioCatalogue: app/models/rest_parameter.rb
#
# Copyright (c) 2009, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

class RestParameter < ActiveRecord::Base
  if ENABLE_CACHE_MONEY
    is_cached :repository => $cache
    index [ :submitter_type, :submitter_id ]
  end
  
  acts_as_trashable
  
  acts_as_annotatable
  
  validates_presence_of :name, 
                        :param_style
                        
  has_submitter
  
  validates_existence_of :submitter # User must exist in the db beforehand.

  if ENABLE_SEARCH
    acts_as_solr(:fields => [ :name, :description, :submitter_name, { :associated_service_id => :r_id } ] )
  end

  if USE_EVENT_LOG
    acts_as_activity_logged(:models => { :culprit => { :model => :submitter } })
  end

  # ===============
  # The :constrained_options field is a serialised array of values.
  # (See: http://www.salsaonrails.eu/2009/01/02/hash-serialization-in-an-activerecord-model for info)
  # ---------------
  
  serialize :constrained_options, Array
  
  def after_initialize
    self.constrained_options ||= [ ]
  end
  
  # ===============
  
  # For the given rest_method object, find duplicate entry based on 'param_name'
  def self.check_duplicate(rest_method, param_name, make_unique=false)
    param_name.gsub!("UNIQUE_TO_METHOD_#{rest_method.id}-", '') unless make_unique
    
    param = nil
    
    param = rest_method.request_parameters.find_by_name(param_name)

    if param.nil?
      unique_param_name = "UNIQUE_TO_METHOD_#{rest_method.id}-" + param_name
      param = rest_method.request_parameters.find_by_name(unique_param_name)
    end
    
    return param # RestParameter || nil
  end

  # Check that a given param exists for the given rest_service object
  def self.check_exists_for_rest_service(rest_service, param_name, make_unique=false)
    param = nil
    
    rest_service.rest_resources.each do |resource|
      resource.rest_methods.each { |method| 
        param = RestParameter.check_duplicate(method, param_name, make_unique)
        break unless param.nil?
      }
      break unless param.nil?
    end
    
    return param # RestParameter || nil
  end
  
  def associated_service_id
    BioCatalogue::Mapper.map_compound_id_to_associated_model_object_id(BioCatalogue::Mapper.compound_id_for(self.class.name, self.id), "Service")
  end

end
