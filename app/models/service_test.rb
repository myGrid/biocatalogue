# BioCatalogue: app/models/service_test.rb
#
# Copyright (c) 2009, University of Manchester, The European Bioinformatics
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details


class ServiceTest < ActiveRecord::Base
  if ENABLE_CACHE_MONEY
    is_cached :repository => $cache
    index :test_type
    index [ :test_type, :test_id ]
  end
  
  belongs_to :service
  
  belongs_to :test,
             :polymorphic => true,
             :dependent => :destroy
  
  has_many :test_results, 
           :dependent => :destroy
  
  has_many :relationships, :as => :subject, :dependent => :destroy
  
  validates_presence_of :service_id,
                        :test_type
                        :test_id
                        
  validates_associated :test
  
  if USE_EVENT_LOG
    acts_as_activity_logged(:models => { :referenced => { :model => :service } })
  end
  
  def latest_test_result
    self.test_results.last || TestResult.new(:result => -1, :created_at => Time.now)
  end
  
  def recent_test_results(limit=5)
    TestResult.find(:all, :conditions => ["service_test_id=?", self.id], 
                          :limit => limit, :order => 'created_at DESC') || [ TestResult.new(:result => -1, :created_at => Time.now) ]
  end
  
  def latest_status
    BioCatalogue::Monitoring::ServiceTestStatus.new(self)
  end
  
  def activated?
    !self.activated_at.blank?
  end
  
  def activate!
    unless !self.activated_at.blank?
      begin
        self.activated_at = Time.now
        self.save!
        return true
      rescue Exception => ex
        logger.error("Failed to activate service_test #{self.id}. Exception:")
        logger.error(ex)
        return false
      end
    end
    logger.error("Service test with #{self.id} was already activated. Exception:")
    return false
  end
  
  def deactivate!
    unless self.activated_at.blank?
      begin
        self.activated_at = nil
        self.save!
        return true
      rescue Exception => ex
        logger.error("Failed to deactivate service_test #{self.id}. Exception:")
        logger.error(ex)
        return false
      end
    end
    logger.error("Service test with #{self.id} was already deactivated. Exception:")
    return false
  end
  
  
  
  def status_changed?
    results = self.test_results.last(2)
    case results.length
      when 0
        return false
      when 1
        return true
      when 2
        stat1 = BioCatalogue::Monitoring::TestResultStatus.new(results[0])
        stat2 = BioCatalogue::Monitoring::TestResultStatus.new(results[1])
        if stat1.label == stat2.label
          return false
        end
        return true
    end
    
  end
  
  def monitored_since(format=true)
    unless self.test_results.empty?
      return self.test_results.first.created_at.strftime("%A %B %d , %Y") if format
      return self.test_results.first.created_at
    end
    return nil
  end
  
  def failing_since
    last_result = self.test_results.last
    if last_result.result > 0
      if self.test_results.count == 1
        return last_result.created_at
      end
      last_success = TestResult.find(:first, :conditions => ["service_test_id=? AND result=0 ", self.id], 
                                              :order => 'created_at DESC')
      unless last_success.nil?
        return TestResult.find(:all, :conditions => ["service_test_id=? AND result=1 AND created_at > ? ", 
                                                                          self.id, last_success.created_at],
                                                            :order => 'created_at ASC').first.created_at
      end
      return self.test_results.first.created_at
    end
    return nil
  end
  
end
