# BioCatalogue: app/models/service_provider.rb
#
# Copyright (c) 2008, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

class ServiceProvider < ActiveRecord::Base
  if ENABLE_CACHE_MONEY
    is_cached :repository => $cache
    index :name
  end
  
  acts_as_trashable
  
  acts_as_annotatable
  
  acts_as_annotation_source
  
  virtual_field_from_annotation_with_fallback :display_name, :name, "display_name"
  
  has_many :service_deployments
  
  has_many :services,
           :through => :service_deployments,
           :uniq => true
  
  validates_presence_of :name
  
  if ENABLE_SEARCH
    acts_as_solr(:fields => [ :name ] )
  end
  
  if USE_EVENT_LOG
    acts_as_activity_logged
  end
  
  def tags_from_services
    services = Service.find(:all, 
                            :conditions => { :service_deployments => { :service_providers => { :id => self.id } } }, 
                            :joins => [ { :service_deployments => :provider } ],
                            :include => [ :tag_annotations ])
    
    # Need to take into account counts, as well as lowercase/uppercase
    tags_hash = { }
    
    services.each do |service|
      # HACK: unfortunately the :finder_sql for the Service :tag_annotations association is not taken into account,
      # so need to manually weed out non-tag annotations here.
      service.tag_annotations.each do |ann|
        if ann.attribute_name.downcase == "tag"
          if tags_hash.has_key?(ann.value.downcase)
            tags_hash[ann.value.downcase]['count'] += 1
          else
            tags_hash[ann.value.downcase] = { 'name' => ann.value, 'count' => 1 }
          end
        end
      end
    end
    
    return BioCatalogue::Tags.sort_tags_alphabetically(tags_hash.values)
  end
end
