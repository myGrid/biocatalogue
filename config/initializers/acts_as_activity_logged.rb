require File.expand_path('../../../lib/acts_as_activity_logged/activity_log', __FILE__)
require File.expand_path('../../../lib/acts_as_activity_logged/acts_as_activity_logged', __FILE__)

ActiveRecord::Base.send :include, NewBamboo::Acts::ActivityLogged