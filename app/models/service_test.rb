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
    !self.test.activated_at.nil?
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
  
end
