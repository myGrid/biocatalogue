# BioCatalogue: app/models/user.rb
#
# Copyright (c) 2008-2010, University of Manchester, The European Bioinformatics
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

require 'digest/sha1'

class User < ActiveRecord::Base
  if ENABLE_CACHE_MONEY
    is_cached :repository => $cache
    index :email
  end

  include RPXNow::UserIntegration
  
  if ENABLE_TRASHING
    acts_as_trashable
  end
  
  has_many :client_applications
  has_many :tokens, :class_name=>"OauthToken",:order=>"authorized_at desc",:include=>[:client_application]
  
  acts_as_annotatable :name_field => :display_name
  acts_as_annotation_source
  
  acts_as_favouriter

  has_many :services,
           :as => "submitter"
  
  has_many :saved_searches,
           :dependent => :destroy
  
  has_many :responsibility_requests, 
           :dependent => :destroy
           
  has_many :service_responsibles,
           :dependent => :destroy

  if USE_EVENT_LOG
    acts_as_activity_logged
  end

  if ENABLE_SEARCH
    searchable :if => proc{|u| u.activated?} do
        text :display_name, :affiliation, :country
    end
  end

  # For users with external accounts (e.g they registered through RPX)
  # email and password confirmation isn't performed. The password and email
  # will be saved nonetheless.
  validates_presence_of       :password, :if => :password_required?
  validates_presence_of       :password_confirmation, :if => :password_required?
  validates_confirmation_of   :password, :if => :password_required?
  
  validates_presence_of       :email, :if => :email_required?
  validates_confirmation_of   :email, :if => :email_required?
  validates_uniqueness_of     :email, :case_sensitive => false, :if => :email_required?
  validates_email_format_of   :email
  validates_email_format_of   :public_email, { :allow_blank => true, :allow_nil => true }
  
  # TODO: this, with allow/ignore nil - validates_uniqueness_of :identifier, :case_sensitive => false

  attr_protected  :id, :salt, :crypted_password, :activated_at, :security_token, :role_id, :identifier
  
  attr_accessor   :password
  
  before_save     :encrypt_password
  before_create   :generate_activation_code,
                  :generate_default_display_name
  
  def to_json
    generate_json_with_collections("default")
  end 
  
  def to_inline_json
    generate_json_with_collections(nil, true)
  end
  
  def to_custom_json(collections)
    generate_json_with_collections(collections)
  end

  # Authenticates a user by their login name and unencrypted password.  Returns the user or nil.
  def self.authenticate(login, password)
    return nil if login.blank? or password.blank?

    # Check for a User with email matching 'login'
    # Old Rails 2 style
    #u = find(:first, :conditions => ["email = ?", login])
    u = where("email = ?", login).first

    u && u.activated? && u.authenticated?(password) ? u : nil
  end
  
  def self.count_activated
    User.count(:conditions => "users.activated_at IS NOT NULL")
  end
  
  # Returns an ordered Array of Hashes that provide the top curators info.
  # E.g.:
  #   [ { 'id' => '5', 'name' => 'John Doe', 'count' => '2445', 'roles' => [ :curator ] }, 
  #     { 'id' => '46', 'name' => 'Jill Doe', 'count' => '345', 'roles' => [ ] }, 
  #     { 'id' => '50', 'name' => 'Jack Doe', 'count' => '210', 'roles' => [ :admin, :curator ] } ]
  # where "count" is the total number of annotations provided by that user.
  def self.top_curators(limit=10)
    # NOTE: this query has only been tested to work with MySQL 5.0.x
    sql = "SELECT users.id AS id, users.display_name AS name, users.country as country, COUNT(*) AS count, users.role_id AS role_id 
            FROM users
            INNER JOIN annotations ON annotations.source_type = 'User' AND annotations.source_id = users.id 
            GROUP BY users.id
            ORDER BY COUNT(*) DESC
            LIMIT #{limit}"
    
    output = User.connection.select_all(User.send(:sanitize_sql, sql))
    
    # Add roles info
    output.each do |o|
      o['roles'] = User.roles_from(o['role_id'].to_i)
      o.delete('role_id')
    end
    
    return output
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
    
    Service.connection.select_all(Service.send(:sanitize_sql, sql)).each do |x|
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
  
  def deactivate!
    begin
      self.activated_at = nil
      self.security_token = nil
      self.save!
      return true
    rescue Exception => ex
      logger.error("Failed to deactivate user #{self.id}. Exception:")
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

    # self.send(:update_without_callbacks) # Old Rails 2 style

    # Rails 3 way to update a single attribute, without calling save.
    # Validation and callbacks is skipped.
    # updated_at/updated_on column is not updated if that column is available.
    self.update_column(:last_active, time)

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
  
  # TODO: fix confusion here; this doesn't just retrieve the "other" services a user is responsible for.
  def other_services_responsible(page=1, per_page=PAGE_ITEMS_SIZE)
    Service.paginate(:page => page,
                     :per_page => per_page,
                     :joins => [ :service_responsibles ],
                     :conditions => [ "service_responsibles.user_id = ? AND service_responsibles.status = 'active'", 
                                     self.id ])
  end
  
  # TODO: see #other_services_responsible; need to clarify how these two methods are related and possibly combine/separate out the logic somewhere else.
  def active_services_responsible_for
    # Old Rails 2 style
    #Service.all(                 :joins => [ :service_responsibles ],
    #                             :conditions => [ "service_responsibles.user_id = ? AND service_responsibles.status = 'active'", self.id ])
    Service.joins(:service_responsibles).where(["service_responsibles.user_id = ? AND service_responsibles.status = 'active'", self.id ])
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
  
  def roles
    r = [ ]
    r << :admin if is_admin?
    r << :curator if is_curator?
    return r
  end
  
  def self.roles_from(role_id)
    r = [ :admin, :curator ] if role_id == 1 
    r = [ :curator ] if role_id == 2
    return r
  end
  
  # make user an admin
  def make_curator!
    unless self.is_curator?
      begin
        self.role_id = 2
        self.save!
        return true
      rescue Exception => ex
        logger.error("There was a problem making user a curator");
        logger.error(ex)
      end
    end
  end    
  # remove admin privileges
  def remove_curator!
    unless !self.is_curator?
      begin
        self.role_id = nil
        self.save!
        return true
      rescue Exception => ex
        logger.error("There was a problem removing user as a curator");
        logger.error(ex)
      end
    end
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

  def generate_json_with_collections(collections, make_inline=false)    
    collections ||= []

    allowed = %w{ saved_searches }
    
    if collections.class==String
      collections = case collections.strip.downcase
                      when "saved_searches"
                        %w{ saved_searches }
                      when "default"
                        %w{ }
                      else []
                    end
    else
      collections.each { |x| x.downcase! }
      collections.uniq!
      collections.reject! { |x| !allowed.include?(x) }
    end
        
    data =     {
      "user" => {
        "name" => BioCatalogue::Util.display_name(self),
        "affiliation" => self.affiliation,
        "public_email" => self.public_email,
        "joined" => (self.activated_at ? self.activated_at.iso8601 : nil),
        "location" => BioCatalogue::Api::Json.location(self.country)
      }
    }

    collections.each do |collection|
      case collection.downcase
        when "saved_searches"
          data["user"]["saved_searches"] = BioCatalogue::Api::Json.collection(self.saved_searches)
      end
    end

    unless make_inline
      data["user"]["self"] = BioCatalogue::Api.uri_for_object(self)
      return data.to_json
    else
      data["user"]["resource"] = BioCatalogue::Api.uri_for_object(self)
      return data["user"].to_json
    end
  end # generate_json_with_collections

end
