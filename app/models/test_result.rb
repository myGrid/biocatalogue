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
  
  def responsible_emails
    [self.service_test.service.submitter.email]
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
          
          service = self.service_test.service
          current_status = BioCatalogue::Monitoring::TestResultStatus.new(self)
          previous_status = BioCatalogue::Monitoring::TestResultStatus.new(previous)
          
          
          if ENABLE_TWITTER
            BioCatalogue::Util.say "Called TestResult#update_status. A status change has occurred so submitting a job to tweet about..."
            msg = "Service '#{BioCatalogue::Util.display_name(service)}' has a test change status from #{previous_status.label} to #{current_status.label} (#{self.created_at.strftime("%Y-%m-%d %H:%M %Z")})"
            Delayed::Job.enqueue(BioCatalogue::Jobs::PostTweet.new(msg), 0, 5.seconds.from_now)
          end
          
          unless MONITORING_STATUS_CHANGE_RECIPIENTS.empty?
            
            status_recipients_emails = MONITORING_STATUS_CHANGE_RECIPIENTS
            status_recipients_emails.concat(self.responsible_emails) if NOTIFY_SERVICE_RESPONSIBLE
            
            BioCatalogue::Util.say "Called TestResult#update_status. A status change has occurred so emailing the special set of recipients about it..."
            subject = "[BioCatalogue] Service '#{BioCatalogue::Util.display_name(service)}' has a test change status from #{previous_status.label} to #{current_status.label}"
            text = "A monitoring test status change has occurred! Service '#{BioCatalogue::Util.display_name(service)}' has a test (#{self.service_test.test_type}, ID: #{self.service_test.test_id}) change status from #{previous_status.label} to #{current_status.label}. Last test result message: #{current_status.message}. Go to Service: #{BioCatalogue::Api.uri_for_object(service)}"
            Delayed::Job.enqueue(BioCatalogue::Jobs::StatusChangeEmails.new(subject, text, status_recipients_emails), 0, 5.seconds.from_now)
          end
          
        end
      end
    end
  end
  
end
