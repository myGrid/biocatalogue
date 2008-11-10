class ContentBlob < ActiveRecord::Base
  validates_presence_of :data
  
  if USE_EVENT_LOG
    acts_as_activity_logged
  end
end
