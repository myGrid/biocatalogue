# BioCatalogue: app/models/service.rb
#
# Copyright (c) 2008, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

class Service < ActiveRecord::Base
  if ENABLE_CACHE_MONEY
    is_cached :repository => $cache
    index :unique_code
    index :name
    index [ :submitter_type, :submitter_id ]
  end
  
  after_commit_on_create :tweet_create
  
  acts_as_trashable
  
  acts_as_annotatable
  
  is_testable
  
  acts_as_favouritable
  
  has_many :relationships, :as => :subject, :dependent => :destroy
  
  has_many :service_versions, 
           :dependent => :destroy,
           :order => "created_at ASC"
  
  has_many :service_deployments, 
           :dependent => :destroy
  
  has_submitter
           
  before_validation_on_create :generate_unique_code
  
  attr_protected :unique_code
  
  validates_presence_of :name, :unique_code
  
  validates_uniqueness_of :unique_code
  
  validates_associated :service_versions
  
  validates_associated :service_deployments
  
  validates_associated :service_tests
  
  validates_existence_of :submitter   # User must exist in the db beforehand.
  
  if ENABLE_SEARCH
    acts_as_solr(:fields => [ :name, :unique_code, :submitter_name ] )
  end
  
  if USE_EVENT_LOG
    acts_as_activity_logged(:models => { :culprit => { :model => :submitter } })
  end
  
  def to_param
    "#{self.id}-#{self.unique_code}"
  end
  
  def latest_version
    self.service_versions.last
  end
  
  def latest_deployment
    self.service_deployments.last
  end
  
  def service_version_instances
    self.service_versions.collect{|sv| sv.service_versionified}    
  end
  
  # Gets an array of all the service types that this service has (as part of it's versions).
  def service_types
    types = self.service_versions.collect{|sv| sv.service_versionified.service_type_name}.uniq
    types << "SOAPLAB" unless self.soaplab_server.nil?
    return types
  end
  
  def description
    self.latest_version.service_versionified.description
  end
  
  # Gets an array of all the ServiceProviders
  def providers
    self.service_deployments.collect{|sd| sd.provider}.uniq
  end
  
  def service_version_instances_by_type(type)
    
    types = {'soap' => 'SoapService',
             'rest' => 'RestService'}
             
    instances = service_version_instances
    return  instances.delete_if{ |instance| instance.class.to_s != types[type] } || []
  end
  
  def views_count
    # NOTE: this query has only been tested to work with MySQL 5.0.x
    sql = "SELECT COUNT(*) AS count 
          FROM activity_logs
          WHERE action = 'view' AND activity_logs.activity_loggable_type = 'Service' AND activity_logs.activity_loggable_id = '#{self.id}'"
    
    return ActiveRecord::Base.connection.select_all(sql)[0]['count'].to_i
  end
  
  # Currently finds all services that have same (or parent) categories as this service.
  def similar_services
    services = [ ]
    
    # NOTE: this query has only been tested to work with MySQL 5.0.x
    sql = "SELECT annotations.value AS category_id
          FROM annotations 
          INNER JOIN annotation_attributes ON annotations.attribute_id = annotation_attributes.id
          WHERE annotation_attributes.name = 'category' AND annotations.annotatable_type = 'Service' AND annotations.annotatable_id = '#{self.id}'"
    
    results = ActiveRecord::Base.connection.select_all(sql)
    
    unless results.blank?
      category_ids = results.map{|r| r['category_id'].to_i}
      
      final_category_ids = category_ids.clone
      
      # Add parents
      category_ids.each do |c_id|
        unless (category = Category.find_by_id(c_id)).nil?
          while category.has_parent?
            category = category.parent 
            final_category_ids << category.id
          end
        end
      end
      
      final_category_ids
      
      service_ids = [ ]
      
      final_category_ids.each do |c_id|
        service_ids.concat(BioCatalogue::Categorising.get_service_ids_with_category(c_id, false))
      end
      
      service_ids = service_ids.uniq.reject{|i| i == self.id}
      
      services = Service.find(:all, :conditions => { :id => service_ids })
    end
    
    return services
  end
  
  # IF this is Service is part of a Soaplab Server then this method returns that SoaplabServer entry.
  # Otherwise it returns nil, which indicates that this Service is not part of a Soaplab Server.
  def soaplab_server
    rel = Relationship.find(:first, 
                            :conditions => { :subject_type => "Service", 
                                             :subject_id => self.id, 
                                             :predicate => "BioCatalogue:memberOf", 
                                             :object_type => "SoaplabServer" })
    if rel.nil?
      return nil
    else
      return rel.object
    end
  end
  
protected
  
  def generate_unique_code
    salt = rand 1000000
    
    if self.name.blank?
      errors.add_to_base("Failed to generate the unique code for the Service. The name of the service has not been set yet.")
      return false
    else
      code = "#{Slugalizer.slugalize(self.name)}_#{salt}"
      
      if Service.exists?(:unique_code => code)
        generate_unique_code
      else
        self.unique_code = code
      end
    end
  end
  
  def tweet_create
    puts "I AM TWEETING!"
    # TODO: use delayed_job to queue the tweeting
    BioCatalogue::Twittering.post_service_created(self)
  end
  
end
