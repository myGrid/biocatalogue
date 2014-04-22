# BioCatalogue: app/models/soap_operation.rb
#
# Copyright (c) 2008-2010, University of Manchester, The European Bioinformatics
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

class SoapOperation < ActiveRecord::Base
  if ENABLE_CACHE_MONEY
    is_cached :repository => $cache
    index :soap_service_id
  end
  
  acts_as_annotatable :name_field => :name
  
  acts_as_archived
  
  belongs_to :soap_service
  
  belongs_to :soap_service_port
  
  has_many :soap_inputs,
           :conditions => "soap_inputs.archived_at IS NULL",
           :dependent => :destroy,
           :order => "soap_inputs.name ASC"
           
  has_many :soap_outputs,
           :conditions => "soap_outputs.archived_at IS NULL",
           :dependent => :destroy,
           :order => "soap_outputs.name ASC"
  
  has_many :archived_soap_inputs,
           :class_name => "SoapInput",
           :foreign_key => "soap_operation_id",
           :dependent => :destroy,
           :conditions => "soap_inputs.archived_at IS NOT NULL",
           :order => "soap_inputs.name ASC"
  
  has_many :archived_soap_outputs,
           :class_name => "SoapOutput",
           :foreign_key => "soap_operation_id",
           :dependent => :destroy,
           :conditions => "soap_outputs.archived_at IS NOT NULL",
           :order => "soap_outputs.name ASC"
  
  if ENABLE_SEARCH
    searchable do
      text :name, :parent_port_type, :description
    end
  end
  
  if USE_EVENT_LOG
    acts_as_activity_logged(:models => { :referenced => { :model => :soap_service } })
  end
  
  def associated_service_id
    @associated_service_id ||= BioCatalogue::Mapper.map_compound_id_to_associated_model_object_id(BioCatalogue::Mapper.compound_id_for(self.class.name, self.id), "Service")
  end
  
  def associated_service
    @associated_service ||= Service.find_by_id(associated_service_id)
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

  def as_csv
    id = self.id.to_s
    service_id = self.associated_service.unique_code unless self.associated_service.nil?
    operation = self.name
    description = self.preferred_description
    submitter = self.associated_service.submitter.display_name unless self.associated_service.nil? || self.associated_service.submitter.nil?
    params_order = self.parameter_order
    annotations = self.get_service_tags
    port = get_soap_port self
    return [id, service_id, operation,description,submitter,params_order,annotations, port].flatten
  end

  def get_soap_port soap_op
      port = soap_op.soap_service_port
      if port.nil?
        return ["","","",""]
      else
        return [
            port.name,
            port.protocol,
            port.location,
            port.style
        ]
      end
  end

  def join_array array
    array.compact!
    array.delete('')

    if array.nil? || array.empty? then
      return ''
    else
      if array.count > 1 then
        return array.join(';')
      else
        return array.first.to_s
      end
    end
  end


  def get_service_tags
    list = []
    BioCatalogue::Annotations.get_tag_annotations_for_annotatable(self).each { |ann| list << ann.value_content }
    return list.join("; ")
  end

  # This will attempt to copy over as many annotations as possible from this 
  # SoapOperation to another given SoapOperation.
  # 
  # This is useful to copy over, for example, annotations from an archived operation
  # to another that may have been created as a result of a renamed in the WSDL.
  #
  # This includes annotations on inputs and outputs (matched by name), 
  # excluding archived inputs and output on this operation.
  def copy_annotations_to(op_to, culprit)
    return [ ] if op_to.blank? or culprit.blank? or !op_to.is_a?(SoapOperation)
    
    total_annotations = [ ]
    
    self.annotations.each do |ann|
      new_ann = ann.copy(op_to, culprit)
      total_annotations << new_ann unless new_ann.nil?
    end
    
    %w{ inputs outputs }.each do |t|
      eval("self.soap_#{t}").each do |o1|
        o2 = eval("op_to.soap_#{t}.find_by_name(o1.name)")
        unless o2.nil?
          o1.annotations.each do |ann|
            new_ann = ann.copy(o2, culprit)
            total_annotations << new_ann unless new_ann.nil?
          end
        end
      end
    end
    
    return total_annotations
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
  
private

  def generate_json_with_collections(collections, make_inline=false)
    collections ||= []

    allowed = %w{ inputs outputs }
    
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
      "soap_operation" => {
        "name" => self.name,
        "description" => self.preferred_description,
        "parameter_order" => self.parameter_order,
        "created_at" => self.created_at.iso8601,
        "archived_at" => self.archived? ? self.archived_at.iso8601 : nil
      }
    }

    collections.each do |collection|
      case collection.downcase
        when "inputs"
          data["soap_operation"]["inputs"] = BioCatalogue::Api::Json.collection(self.soap_inputs)
        when "outputs"
          data["soap_operation"]["outputs"] = BioCatalogue::Api::Json.collection(self.soap_outputs)
      end
    end

    unless make_inline
      data["soap_operation"]["self"] = BioCatalogue::Api.uri_for_object(self)
			return data.to_json
    else
      data["soap_operation"]["resource"] = BioCatalogue::Api.uri_for_object(self)
			return data["soap_operation"].to_json
    end
  end # generate_json_with_collections

end
