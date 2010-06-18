# BioCatalogue: app/models/service.rb
#
# Copyright (c) 2008-2009, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details


class Service < ActiveRecord::Base
  if ENABLE_CACHE_MONEY
    is_cached :repository => $cache
    index :unique_code
    index :name
    index [ :submitter_type, :submitter_id ]
  end
  
  after_create :tweet_create
    
  if ENABLE_TRASHING
    acts_as_trashable
  end
  
  acts_as_annotatable
  
  acts_as_favouritable
  
  acts_as_archived
  
  has_many :relationships, 
           :as => :subject, 
           :dependent => :destroy
  
  has_many :service_versions, 
           :dependent => :destroy,
           :order => "created_at ASC"
  
  has_many :service_deployments, 
           :dependent => :destroy
  
  has_many :service_tests, 
           :dependent => :destroy
  
  has_many :responsibility_requests,
           :as => :subject,
           :dependent => :destroy
  
  has_many :service_responsibles,
           :dependent => :destroy
  
  has_submitter
  
  # Custom association for just the 'tag' annotations.
  # This is so that it can be included in eager loading elsewhere.
  has_many :tag_annotations,
           :class_name => "Annotation",
           :as => :annotatable,
           :finder_sql => 'SELECT * 
                          FROM annotations 
                          INNER JOIN annotation_attributes ON annotations.attribute_id = annotation_attributes.id 
                          WHERE annotation_attributes.name = "tag" AND annotations.annotatable_type = "Service" AND annotations.annotatable_id = #{self.id}'
  
  virtual_field_from_annotation_with_fallback :display_name, :name, "display_name"
           
  before_validation_on_create :generate_unique_code
  
  attr_protected :unique_code
  
  validates_presence_of :name, :unique_code
  
  validates_uniqueness_of :unique_code
  
  validates_associated :service_versions
  
  validates_associated :service_deployments
  
  # This causes a "stack level too deep" error because of recursive validates_associated calls in ServiceTest
  #validates_associated :service_tests
  
  validates_existence_of :submitter   # User must exist in the db beforehand.
  
  if ENABLE_SEARCH
    acts_as_solr(:fields => [ :name, :unique_code, :submitter_name ] )
  end
  
  if USE_EVENT_LOG
    acts_as_activity_logged(:models => { :culprit => { :model => :submitter } })
  end
  
  def self.latest(limit=10)
    self.find(:all,
              :order => "created_at DESC",
              :limit => limit)
  end
  
#  def to_param
#    "#{self.id}-#{self.unique_code}"
#  end
  
  def latest_version
    self.service_versions.last
  end
  
  def latest_deployment
    self.service_deployments.last
  end
  
  def service_version_instances
    self.service_versions.collect{|sv| sv.service_versionified}    
  end
  
  def service_version_instances_by_type(type_model_name)
    type_model_name.constantize.find(:all,
                                     :conditions => { :service_versions => { :service_id => self.id } },
                                     :joins => [ :service_version ])
  end 
  
  # Gets an array of all the service types that this service has (as part of it's versions).
  def service_types
    types = self.service_versions.collect{|sv| sv.service_versionified.service_type_name}.uniq
    types << "Soaplab" unless self.soaplab_server.nil?
    return types
  end
  
  def description
    self.latest_version.service_versionified.description
  end
  
  def preferred_description
    # Either the description from the service description doc, 
    # or the last description annotation.
    
    desc = self.description
    
    if desc.blank?
      desc = self.latest_version.service_versionified.annotations_with_attribute("description").first.try(:value)
    end
    
    return desc
  end
  
  # Gets an array of all the ServiceProviders
  def providers
    self.service_deployments.collect{|sd| sd.provider}.uniq
  end
  
  def views_count
    # NOTE: this query has only been tested to work with MySQL 5.0.x
    sql = "SELECT COUNT(*) AS count 
          FROM activity_logs
          WHERE action = 'view' AND activity_logs.activity_loggable_type = 'Service' AND activity_logs.activity_loggable_id = '#{self.id}'"
    
    return ActiveRecord::Base.connection.select_all(sql)[0]['count'].to_i
  end
  
  # Currently finds all services that have same (or parent) categories as this service.
  def similar_services(limit=10)
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
      
      services = Service.find(:all, :conditions => { :id => service_ids[0...limit] })
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
    rel.nil? ? rel : rel.object
  end
  
  def test_scripts(options={})
    scripts = service_test_instances_by_type('TestScript')
    if options[:active_only]
      return scripts.collect{|s| s if s.service_test.activated? }.compact
    end
    scripts
  end
  
  def service_tests_by_type(type)
    ServiceTest.find(:all, :conditions => {:test_type => type, :service_id => self.id})
  end
  
  # e.g. To find all test scripts:  service_test_instances_by_type('TestScript')
  def service_test_instances_by_type(type)
    service_tests_by_type(type).collect{|st| st.test}.compact
  end
  
  # This updates the submitter as well as the submitter of this service as well 
  # as all ServiceDeployment and ServiceVersions underneath it.
  # NOTE: USE THIS WITH CAUTION AS YOU ARE ASSUMING THAT ONE SUBMITTER SUBMITTED EVERYTHING. 
  def update_service_structure_submitter(new_submitter)
    return false if new_submitter.nil?
    
    status = true
    
    unless self.submitter == new_submitter
      self.submitter = new_submitter
      status = status && self.save
    end
    
    self.service_versions.each do |sv|
      unless sv.submitter == new_submitter
        sv.submitter = new_submitter
        status = status && sv.save
      end
    end
    
    self.service_deployments.each do |sd|
      unless sd.submitter == new_submitter
        sd.submitter = new_submitter
        status = status && sd.save
      end
    end
    
    return status
  end
  
  def latest_status
    BioCatalogue::Monitoring::ServiceStatus.new(self)
  end
  
  def latest_test_results_for_all_service_tests(options ={})
    results = self.service_tests.map{ |st| st.latest_test_result if st.activated? }.compact
    if options[:all]
      return self.service_tests.map{ |st| st.latest_test_result  }.compact
    end
    results
  end
  
  # Either return the creation time of the earliest test result
  # for all the service tests or return nil if no test results exist
  def monitored_since
    first_results = self.service_tests.collect{|st| st.test_results.first}.compact
    unless first_results.first.nil?
      return first_results.sort_by{|r| r.created_at}.first.created_at 
    end
    return nil
  end
  
  # Curators and submitters are given full permissions on the 
  # service by adding them to the set of those responsible to
  # manage the service the service by default.  
  def all_responsibles
    curators = User.find(:all, :conditions => {:role_id => [ 1, 2 ]})
    responsibles = self.service_responsibles.collect{|r| r.user if r.status='active'}.compact
    responsibles << self.submitter if self.submitter_type == "User"
    responsibles.concat(curators)
    return responsibles.uniq
  end
  
  def pending_responsibility_requests(limit=5)
    reqs = ResponsibilityRequest.find(:all, :conditions => {:subject_type => self.class.name,
                                                            :subject_id => self.id,
                                                            :status => 'pending'}, :limit => limit)
    return reqs
  end
  
  def run_service_updater!
    # Run SoapService#update_from_latest_wsdl! for all SoapService variants of this Service
    self.service_version_instances_by_type("SoapService").each do |soap_service|
      # The soap_service object is read only so need to refetch the object...
      SoapService.find(soap_service.id).update_from_latest_wsdl!
    end
  end
  
  # Currently only gets the associated object IDs for:
  # - ServiceDeployments
  # - ServiceVersions
  # - SoapService
  # - RestService
  #
  # Note that this is eternally cached.
  #
  # FIXME: this needs to take into account when any new objects of the 
  # type above are added to the Service.
  def associated_object_ids(cache_refresh=false)
    object_ids = nil
      
    cache_key = BioCatalogue::CacheHelper.cache_key_for(:associated_object_ids, "Service", self.id)
  
    if cache_refresh
      Rails.cache.delete(cache_key)
    end
    
    # Try and get it from the cache...
    object_ids = Rails.cache.read(cache_key)
    
    if object_ids.nil?
      
      # It's not in the cache so get the values and store it in the cache...
      
      object_ids = { }
      
      object_ids["ServiceDeployments"] = self.service_deployments.map { |sd| sd.id }
      object_ids["ServiceVersions"] = self.service_versions.map { |sv| sv.id }
      object_ids["SoapServices"] = self.service_version_instances_by_type("SoapService").map { |ss| ss.id }
      object_ids["RestServices"] = self.service_version_instances_by_type("RestService").map { |rs| rs.id }
      
      # Finally write it to the cache...
      Rails.cache.write(cache_key, object_ids)
      
    end
    
    return object_ids
  end
  
  def annotations_activity_logs(since, limit=100)
    obj_ids = self.associated_object_ids
    
    ActivityLog.find(:all,
      :conditions => [ "action = 'create' AND activity_loggable_type = 'Annotation' AND (
                       (activity_loggable_type = 'Service' AND activity_loggable_id = ?) OR (referenced_type = 'Service' AND referenced_id = ?) OR
                       (activity_loggable_type = 'ServiceDeployment' AND activity_loggable_id IN (?)) OR (referenced_type = 'ServiceDeployment' AND referenced_id IN (?)) OR
                       (activity_loggable_type = 'ServiceVersion' AND activity_loggable_id IN (?)) OR (referenced_type = 'ServiceVersion' AND referenced_id IN (?)) OR
                       (activity_loggable_type = 'SoapService' AND activity_loggable_id IN (?)) OR (referenced_type = 'SoapService' AND referenced_id IN (?)) OR
                       (activity_loggable_type = 'RestService' AND activity_loggable_id IN (?)) OR (referenced_type = 'RestService' AND referenced_id IN (?))
                       ) AND created_at >= ?", 
                       "Service", 
                       self.id,
                       (obj_ids["ServiceDeployments"] || []),
                       (obj_ids["ServiceDeployments"] || []),
                       (obj_ids["ServiceVersions"] || []),
                       (obj_ids["ServiceVersions"] || []),
                       (obj_ids["SoapServices"] || []),
                       (obj_ids["SoapServices"] || []),
                       (obj_ids["RestServices"] || []),
                       (obj_ids["RestServices"] || []),
                       since ],
      :order => "created_at DESC",
      :limit => limit)
  end
  
  def activate_service_tests!
    self.service_tests.each do |t|
      if !t.activated?
        t.activate!
      end
    end
  end
  
  def deactivate_service_tests!
    self.service_tests.each do |t|
      if t.activated?
        t.deactivate!
      end
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
    if ENABLE_TWITTER
      BioCatalogue::Util.say "Called Service#tweet_create to submit job to tweet"
      msg = "New #{self.service_types[0]} service: #{BioCatalogue::Util.display_name(self)} - #{BioCatalogue::Api.uri_for_object(self)}"
      Delayed::Job.enqueue(BioCatalogue::Jobs::PostTweet.new(msg), 0, 5.seconds.from_now)
    end
  end
  
end
