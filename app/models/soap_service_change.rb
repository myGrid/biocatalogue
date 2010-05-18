# BioCatalogue: app/models/soap_service_change.rb
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

class SoapServiceChange < ActiveRecord::Base
  validates_presence_of :changelog,
                        :soap_service_id

  belongs_to :soap_service
  
  serialize :changelog, Array
  
  if USE_EVENT_LOG
    acts_as_activity_logged(:models => { :referenced => { :model => :soap_service } })
  end
  
  # Adds an entry to the changelog, but does not save the record.
  def add_entry(entry)
    return if entry.blank?
    self.changelog = [ ] if self.changelog.nil?
    self.changelog << entry 
  end
end
