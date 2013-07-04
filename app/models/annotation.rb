# BioCatalogue: app/models/annotation.rb
#
# Copyright (c) 2009-2011, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details.

#=====
# This extends the Annotation model defined in the Annotations plugin.
#=====

#require_dependency Rails.root.to_s + '/vendor/plugins/annotations/lib/app/models/annotation'
require_dependency File.join(Gem.loaded_specs['my_annotations'].full_gem_path,'lib','app','models','annotation')
class Annotation < ActiveRecord::Base

#  if ENABLE_CACHE_MONEY
#    is_cached :repository => $cache
#    index :attribute_id, :limit => 5000, :buffer => 100
#    index [ :source_type, :source_id ], :limit => 5000, :buffer => 100
#    index [ :annotatable_type, :annotatable_id ], :limit => 5000, :buffer => 100
#  end

  # [OLD] Always eager load the annotation value object.
  #
  # TODO: this may have negative effects on peformance 
  # and so usage needs to be thoroughly analysed.
  # This may especially be bad in cases where the value
  # object contains a lot of data.
  #
  # UPDATE 2011-08-18 (Jits): this is causing many queries to fail.
  # So commented out for now. Wherever possible, try and use:
  #   :include => [ :value ]
  # ... in your Annotation finders.
  # OR use the new named scope "include_values" which has been added 
  # to the Annotation model in the plugin itself.
  #default_scope :include => [ :value ]

  has_many :annotation_properties, :dependent => :destroy
  has_one :annotation_parsed_type, :dependent => :destroy

  if ENABLE_TRASHING
    acts_as_trashable
  end
  
  after_destroy :process_post_destroy_custom_logic
  
  if USE_EVENT_LOG
    acts_as_activity_logged :models => { :culprit => { :model => :source },
                                         :referenced => { :model => :annotatable } }
  end
  
  if ENABLE_SEARCH
    acts_as_solr(:fields => [ :value_for_solr, 
                              { :associated_service_id => :r_id },
                              { :associated_soap_operation_id => :r_id },
                              { :associated_rest_method_id => :r_id },
                              { :associated_service_provider_id => :r_id },
                              { :associated_user_id => :r_id }, 
                              { :associated_registry_id => :r_id } ])
  end
  
  def to_json
    generate_json_and_make_inline(false)
  end 
  
  def to_inline_json
    generate_json_and_make_inline(true)
  end
  
  def value_hash
    data = case self.value_type
      when 'Category'
        {
          "resource" => BioCatalogue::Api.uri_for_object(self.value),
        }
      when 'Tag'
        {
          "resource" => BioCatalogue::Api.uri_for_path(BioCatalogue::Tags.generate_tag_show_uri(self.value.name)),
        }
      else
        {
          "resource" => nil,
        }
    end
    
    data["type"] = self.value_type
    data["content"] = self.value_content
    
    return data
  end
  
  # Copies this annotation to a new annotatable and gives it a new source as specified.
  #
  # Also creates an appropriate Relationship object to keep a provenance of the copy.
  def copy(new_annotatable, new_source)
    return nil if new_annotatable.blank? or new_source.blank?
    
    new_ann = Annotation.create(
                :attribute => self.attribute,
                :annotatable => new_annotatable,
                :source => new_source,
                :value => self.value)   # TODO: this copies over the *reference* to the actual annotation value object. Is this okay behaviour? 
    
    if !new_ann.nil? and new_ann.valid? 
      Relationship.create(:subject => new_ann, :object => self, :predicate => "BioCatalogue:copiedFrom")
    else
      new_ann = nil
    end
    
    return new_ann
  end

  def associated_service_id
    @associated_service_id ||= BioCatalogue::Mapper.map_compound_id_to_associated_model_object_id(BioCatalogue::Mapper.compound_id_for(self.class.name, self.id), "Service")
  end
  
  def associated_service
    @associated_service ||= Service.find_by_id(associated_service_id)
  end

  def associated_soap_operation_id
    case self.annotatable_type
      when "SoapOperation"
        return self.annotatable_id
      when "SoapInput", "SoapOutput"
        return self.annotatable.soap_operation_id unless self.annotatable.nil?
      else
        nil
    end
  end

  def associated_soap_operation
    @associated_soap_operation ||= SoapOperation.find_by_id(associated_soap_operation_id)
  end
  
  def associated_rest_method_id
    case self.annotatable_type
      when "RestMethod"
        return self.annotatable_id
      when "RestMethodParameter", "RestMethodParameter"
        return self.annotatable.rest_method_id unless self.annotatable.nil?
      when "RestParameter", "RestRepresentation"
        return self.annotatable.associated_rest_method_id unless self.annotatable.nil?
      else
        nil
    end
  end

  def associated_rest_method
    @associated_rest_method ||= RestMethod.find_by_id(associated_rest_method_id)
  end
  
  def associated_service_provider_id
    @associated_service_provider_id ||= BioCatalogue::Mapper.map_compound_id_to_associated_model_object_id(BioCatalogue::Mapper.compound_id_for(self.class.name, self.id), "ServiceProvider")
  end

  def associated_service_provider
    @associated_service_provider ||= ServiceProvider.find_by_id(associated_service_provider_id)
  end
  
  def associated_user_id
    @associated_user_id ||= BioCatalogue::Mapper.map_compound_id_to_associated_model_object_id(BioCatalogue::Mapper.compound_id_for(self.class.name, self.id), "User")
  end

  def associated_user
    @associated_user ||= User.find_by_id(associated_user_id)
  end
  
  def associated_registry_id
    @associated_registry_id ||= BioCatalogue::Mapper.map_compound_id_to_associated_model_object_id(BioCatalogue::Mapper.compound_id_for(self.class.name, self.id), "Registry")
  end

  def associated_registry
    @associated_registry ||= Registry.find_by_id(associated_registry_id)
  end
  
protected
  
  def value_for_solr
    return self.value_content
  end
  
  def process_post_destroy_custom_logic
    if self.attribute_name.downcase == 'example_endpoint'
      url_monitors = UrlMonitor.all(:conditions => [ "parent_id = ? AND parent_type = ?", self.id, "Annotation" ])
      url_monitors.each do |u|
        u.destroy
      end
    end
  end
  
  def generate_json_and_make_inline(make_inline)
    data = {
      "annotation" => {
        "version" => self.version,
        "annotatable" => {
          "resource" => BioCatalogue::Api.uri_for_object(self.annotatable),
          "type" => self.annotatable_type,
          "name" => BioCatalogue::Util.display_name(self.annotatable)
        },
        "source" => {
          "resource" => BioCatalogue::Api.uri_for_object(self.source),
          "type" => self.source_type,
          "name" => BioCatalogue::Util.display_name(self.source)
        },
        "attribute" => {
          "resource" => BioCatalogue::Api.uri_for_object(self.attribute),
          "name" => self.attribute.name.downcase,
          "identifier" => self.attribute.identifier.downcase
        },
        "value" => self.value_hash,
        "created" => self.created_at.iso8601,
      }
    }

    data["annotation"]["modified"] = self.updated_at.iso8601 unless self.created_at == self.updated_at

    unless make_inline
      data["annotation"]["self"] = BioCatalogue::Api.uri_for_object(self)
			return data.to_json
    else
      data["annotation"]["resource"] = BioCatalogue::Api.uri_for_object(self)
			return data["annotation"].to_json
    end
  end # generate_json_and_make_inline
  
end