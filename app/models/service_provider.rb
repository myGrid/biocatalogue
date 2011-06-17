# BioCatalogue: app/models/service_provider.rb
#
# Copyright (c) 2008-2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

class ServiceProvider < ActiveRecord::Base
  if ENABLE_CACHE_MONEY
    is_cached :repository => $cache
    index :name
  end
  
  after_save :mail_admins_if_required
  
  if ENABLE_TRASHING
    acts_as_trashable
  end
  
  acts_as_annotatable
  acts_as_annotation_source
  
  has_many :service_deployments
  
  has_many :services,
           :through => :service_deployments,
           :uniq => true,
           :dependent => :destroy
           
  has_many :service_provider_hostnames,
           :dependent => :destroy
           
  validates_presence_of :name
  validates_uniqueness_of :name
  
  if ENABLE_SEARCH
    acts_as_solr(:fields => [ :name ] )
  end
  
  if USE_EVENT_LOG
    acts_as_activity_logged
  end
  
  def to_json
    generate_json_and_make_inline(false)
  end 
  
  def to_inline_json
    generate_json_and_make_inline(true)
  end

  def preferred_description
    self.annotations_with_attribute('description').last.try(:value)
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

  def merge_into(provider, *args)
    success = false
    
    return success unless provider.class==ServiceProvider

    options = args.extract_options!    
    options.reverse_merge!(:print_log => false,
                           :migrate_deployments => true,
                           :migrate_annotations => true,
                           :migrate_hostnames => true)
    
    options.each { |k, v| 
      return success unless v.class==TrueClass || v.class==FalseClass
    }
    
    transaction do
      #update deployments
      if options[:migrate_deployments]
        puts "", "Migrating Service Deployments..." if options[:print_log]
        self.service_deployments.each { |d|
          d.service_provider_id = provider.id 
          d.save!
          puts d.inspect if options[:print_log] 
        } 
        puts "Service Deployments Migrated!" if options[:print_log] 
      end 
    
      # update hostnames
      if options[:migrate_hostnames]
        puts "", "Migrating Hostnames..." if options[:print_log]
        self.service_provider_hostnames.each { |h|
          h.service_provider_id = provider.id
          h.save!
          puts h.inspect if options[:print_log] 
        }
        puts "Hostnames Migrated!" if options[:print_log] 
      end
      
      # update annotations
      if options[:migrate_annotations]
        puts "", "Migrating Annotations..." if options[:print_log]
        self.annotations.each { |a|
          begin
            a.annotatable_id = provider.id
            a.save!
            puts a.inspect if options[:print_log] 
          rescue
            if options[:print_log]
              puts "The following annotation could not be migrated and has been deleted:"
              puts a.inspect
            end
            a.destroy
          end
        }
        
        self.annotations_by.each { |a|
          begin
            a.source_id = provider.id
            a.save!
            puts a.inspect if options[:print_log] 
          rescue
            if options[:print_log]
              puts "The following annotation could not be migrated and has been deleted:"
              puts a.inspect
            end
            a.destroy
          end
        }
        puts "Annotations Migrated!" if options[:print_log] 
      end
      
      # refresh changed associations before destroying self
      self.service_deployments(true)
      self.service_provider_hostnames(true) 
      self.annotations(true)
      
      puts "", "Deleting Orphaned Service Provider: #{self.inspect}"       
      self.destroy
      
      success = true
    end
    
    return success
  end

  def update_hostnames!
    begin
      transaction do
        # get all hostnames as strings
        existing_hostnames = {} # { "hostname" => boolean } where 'boolean' indicates whether the hostname has >= 1 services associated
        self.service_provider_hostnames.each { |h| existing_hostnames.merge!( {h.hostname => false} ) }
        
        # create new hostnames as appropriate
        self.service_deployments.each do |sd|
          hostname = Addressable::URI.parse(sd.endpoint).host
          
          if existing_hostnames.has_key?(hostname)
            existing_hostnames[hostname] = true
          else
            new_hostname = ServiceProviderHostname.create(:hostname => hostname, :service_provider_id => self.id)
            existing_hostnames.merge!( {hostname => true} )
          end
        end
        
        # cleanup UNUSED hostnames
        self.service_provider_hostnames.each { |h| 
          ServiceProviderHostname.delete(h.id) unless existing_hostnames[h.hostname]
        }
      end # transaction
    rescue Exception => ex
      logger.error("Failed to update hostnames for ServiceProvider with ID: #{self.id}. Exception:")
      logger.error(ex.message)
      logger.error(ex.backtrace.join("\n"))
    end
  end
  
private
  
  def mail_admins_if_required    
    # send emails to biocat admins
    if self.services.empty?
      recipients = []
      User.admins.each { |user| recipients << user.email }

      UserMailer.deliver_orphaned_provider_notification(recipients.join(", "), SITE_BASE_HOST.gsub("http://", '').gsub("https://", ''), self)
    end
  end
  
  def generate_json_and_make_inline(make_inline)
    data = {
      "service_provider" => {
        "name" => BioCatalogue::Util.display_name(self),
        "description" => self.preferred_description
      }
    }

    unless make_inline
      list = []
      self.service_provider_hostnames.each { |hostname| list << hostname.hostname }
      data["service_provider"]["hostnames"] = list
      data["service_provider"]["self"] = BioCatalogue::Api.uri_for_object(self)
			return data.to_json
    else
      data["service_provider"]["resource"] = BioCatalogue::Api.uri_for_object(self)
			return data["service_provider"].to_json
    end
  end # generate_json_and_make_inline

end
