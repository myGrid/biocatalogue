# BioCatalogue: app/models/user.rb
#
# Copyright (c) 2008, University of Manchester, The European Bioinformatics
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

require 'digest/sha1'

class User < ActiveRecord::Base
  if ENABLE_CACHE_MONEY
    is_cached :repository => $cache
    index :email
  end

  include RPXNow::UserIntegration
  
  acts_as_trashable
  
  acts_as_annotatable
  acts_as_annotation_source
  
  acts_as_favouriter

  has_many :services,
           :as => "submitter"
  
  has_many :responsibility_requests, 
            :dependent => :destroy
  has_many :service_responsibles,
            :dependent => :destroy

  if USE_EVENT_LOG
    acts_as_activity_logged
  end

  if ENABLE_SEARCH
    acts_as_solr(:fields => [ :display_name, :affiliation, :country ],
                 :if => proc{|u| u.activated?})
  end
  
  validates_presence_of       :password, :if => :password_required?
  validates_presence_of       :password_confirmation, :if => :password_required?
  validates_confirmation_of   :password, :if => :password_required?
  
  validates_presence_of       :email, :if => :email_required?
  validates_confirmation_of   :email, :if => :email_required?
  validates_uniqueness_of     :email, :case_sensitive => false, :if => :email_required?
  validates_email_veracity_of :email, :public_email
  
  # TODO: this, with allow/ignore nil - validates_uniqueness_of :identifier, :case_sensitive => false

  attr_protected  :id, :salt, :crypted_password, :activated_at, :security_token, :role_id, :identifier
  
  attr_accessor   :password
  
  before_save     :encrypt_password
  before_create   :generate_activation_code,
                  :generate_default_display_name

  # Authenticates a user by their login name and unencrypted password.  Returns the user or nil.
  def self.authenticate(login, password)
    return nil if login.blank? or password.blank?

    # Check for a User with email matching 'login'
    u = find(:first, :conditions => ["email = ?", login])

    u && u.activated? && u.authenticated?(password) ? u : nil
  end
  
  def self.count_activated
    User.count(:conditions => "users.activated_at IS NOT NULL")
  end
  
  # Returns an ordered Array of Hashes that provide the top curators info.
  # E.g.:
  #   [ { 'id' => '5', 'name' => 'John Doe', 'count' => '2445' }, { 'id' => '46', 'name' => 'Jill Doe', 'count' => '345' }, { 'id' => '50', 'name' => 'Jack Doe', 'count' => '210' } ]
  # where "count" is the total number of annotations provided by that user.
  def self.top_curators(limit=10)
    # NOTE: this query has only been tested to work with MySQL 5.0.x
    sql = "SELECT users.id AS id, users.display_name AS name, users.country as country, COUNT(*) AS count 
            FROM users
            INNER JOIN annotations ON annotations.source_type = 'User' AND annotations.source_id = users.id 
            GROUP BY users.id
            ORDER BY COUNT(*) DESC
            LIMIT #{limit}"
    
    return ActiveRecord::Base.connection.select_all(ActiveRecord::Base.send(:sanitize_sql, sql))
  end
  
  # Returns a hash where the keys are User IDs (as Strings) and the values are the number of services (Integer) that that user has submitted.
  # TODO: need take into account individual ServiceDeployments etc.
  def self.services_counts
    # NOTE: this query has only been tested to work with MySQL 5.0.x
    sql = "SELECT services.submitter_id AS user_id, COUNT(*) AS count 
            FROM services
            WHERE services.submitter_type = 'User'
            GROUP BY services.submitter_id"
    
    results = Hash.new 0
    
    ActiveRecord::Base.connection.select_all(ActiveRecord::Base.send(:sanitize_sql, sql)).each do |x|
      results[x['user_id']] = x['count'].to_i
    end
    
    return results
  end

  def authenticated?(password)
    crypted_password == encrypt(password)
  end

  def activate!
    begin
      self.activated_at = Time.now
      self.security_token = nil
      self.save!
      return true
    rescue Exception => ex
      logger.error("Failed to activate user #{self.id}. Exception:")
      logger.error(ex)
      return false
    end
  end

  def activated?
    !self.activated_at.blank?
  end

  def password_required?
    (crypted_password.blank? || !password.blank?) && self.identifier.blank?
  end
  
  def email_required?
    self.identifier.blank?
  end

  def annotation_source_name
    self.display_name
  end

  def generate_security_token!
    begin
      generate_security_token
      self.save!
      return true
    rescue Exception => ex
      logger.error("Failed to generate the security token for user #{self.id}. Exception:")
      logger.error(ex)
      return false
    end
  end

  def reset_password!(password = nil, password_confirmation = nil)
    begin
      self.password = password
      self.password_confirmation = password_confirmation
      self.security_token = nil
      self.save!
      return true
    rescue Exception => ex
      logger.error("Failed to reset password for user #{self.id}. Exception:")
      logger.error(ex)
      return false
    end
  end
  
  def allow_merge?
    (self.services.count == 0) && (self.annotations_by.count == 0)
  end
  
  def update_last_active time
    class << self
      def record_timestamps; false; end
    end
    self.last_active = time
    self.send(:update_without_callbacks)
    class << self
      remove_method :record_timestamps
    end
  end
  
  def annotated_service_ids
    service_ids = self.annotations_by.collect do |a|
      BioCatalogue::Mapper.map_compound_id_to_associated_model_object_id(BioCatalogue::Mapper.compound_id_for(a.annotatable_type, a.annotatable_id), "Service")      
    end
    service_ids.compact.uniq
  end
  
  def is_admin?
    [ 1 ].include? self.role_id
  end
  
  def is_curator?
    [ 1, 2 ].include? self.role_id  
  end

  def self.admins
    User.find_all_by_role_id(1)
  end
  
  def self.curators
    User.find_all_by_role_id(2)
  end
  
private

  # Encrypts password with the salt.
  def self.encrypt(password, salt)
    Digest::SHA1.hexdigest("--#{salt}--#{password}--")
  end

  #
  def encrypt_password
    return if password.blank?
    self.salt = Digest::SHA1.hexdigest("--#{Time.now.to_s}--#{email}--") if self.salt.nil?
    self.crypted_password = encrypt(password)
  end

  # Encrypts the password with the user salt
  def encrypt(password)
    e = self.class.encrypt(password, salt)

    # Clear password virtual attribute to prevent it from being shown in forms after update
    self.password = nil
    self.password_confirmation = nil #if self.respond_to?(password_confirmation)
    return e
  end

  # Generate the confirmation key sent by email to activate an account
  def generate_activation_code
    #self.security_token = Digest::SHA1.hexdigest("--#{Time.now.to_s}--#{email}--#{salt}--")
    generate_security_token
  end

    # Generate the confirmation a security token for account activation or password reset
  def generate_security_token
    self.security_token = Digest::SHA1.hexdigest("--#{Time.now.to_s}--#{email}--#{salt}--")
  end

  # Generate a default display name when creating a user for the 1st time
  def generate_default_display_name
    if self.display_name.blank?
      self.display_name = (email.blank? ? "[no name]" : self.email.split("@")[0])
    end
  end

end
