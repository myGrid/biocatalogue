# BioCatalogue: app/models/test_result.rb
#
# Copyright (c) 2009, University of Manchester, The European Bioinformatics
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details


class TestResult < ActiveRecord::Base
  
  before_create :valid_result_range
  
  after_create :update_status
  
  belongs_to :service_test
  
  validates_presence_of :result,
                        :action,
                        :service_test_id
  
  validates_numericality_of :result
  
  # Helper class method to find a "monitorable" object
  # given the monitorable object class name and id 
  def self.find_monitorable(monitorable_str, monitorable_id)
    monitorable_str.constantize.find(monitorable_id)
  end 
  
  def self.new_with_unknown_status
    TestResult.new(:result => -1)
  end
  
  # Results for a given service test
  def self.results_for(service_test, limit=5)
    TestResult.find(:all,
                    :conditions =>  { :service_test_id => service_test.id },
                    :order => "created_at DESC",
                    :limit => limit)
  end
  
  # TODO: (maybe) add an after_create that then creates an activity_log entry IFF the status of this particular
  # service_test has been *changed* from a previous state to a different state (this is useful for news feeds etc).
  
  def valid_result_range
    self.result && self.result > -2 ? true : false
  end
  
  def monitored_service
    Service.find(self.service_test.service_id)
  end
  
  def status
    BioCatalogue::Monitoring::TestResultStatus.new(self)
  end
  
  # previous result id is set to nil for new_with_unknown_status
  def update_status
    if self.service_test.status_changed?
      results = self.service_test.test_results.last(2)
      unless results.empty?
        case results.length
          when 1
            previous = TestResult.new_with_unknown_status
          when 2
            previous = results[0]    
        end
        if USE_EVENT_LOG
          ActivityLog.create(:action => "status_change",
                           :data =>{:current_result_id => self.id, :previous_result_id =>previous.id },
                           :activity_loggable => self.service_test)
        end
      end
    end
  end
  
end
