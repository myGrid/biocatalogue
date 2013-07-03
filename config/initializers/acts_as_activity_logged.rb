require 'lib/acts_as_activity_logged/activity_log'
require 'lib/acts_as_activity_logged/acts_as_activity_logged'

ActiveRecord::Base.send :include, NewBamboo::Acts::ActivityLogged