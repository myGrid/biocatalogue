# Be sure to restart your server when you modify this file

# Uncomment below to force Rails into production mode when
# you don't control web/app server and can't set it the proper way
# ENV['RAILS_ENV'] ||= 'production'

# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '2.3.18' unless defined? RAILS_GEM_VERSION

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')


# FOR DEBUG PURPOSES ONLY:
#require "rbtrace"


Rails::Initializer.run do |config|
  # Settings in config/environments/* take precedence over those specified here.
  # Application configuration should go into files in config/initializers
  # -- all .rb files in that directory are automatically loaded.
  # See Rails::Configuration for more options.

  # Skip frameworks you're not going to use. To use Rails without a database
  # you must remove the Active Record framework.
  # config.frameworks -= [ :active_record, :active_resource, :action_mailer ]

  # Specify gems that this application depends on. 
  # They can then be installed with "rake gems:install" on new installations.
  # config.gem "bj"
  # config.gem "hpricot", :version => '0.6', :source => "http://code.whytheluckystiff.net"
  # config.gem "aws-s3", :lib => "aws/s3" 
  #config.gem 'disqus', :version => '1.0.1'
  #config.gem 'soap4r', :version => '1.5.8'
  #config.gem 'mperham-memcache-client', :version => '>= 1.7.4', :lib => 'memcache', :source => "http://gems.github.com"
  #config.gem 'onyx-cache-money', :version => '>= 0.2.6.1', :lib => 'cache_money', :source => "http://gems.github.com"
  #config.gem 'geokit', :version => '>= 1.3.2'
  #config.gem 'jnunemaker-twitter', :version => '>= 0.6.11', :lib => 'twitter', :source => "http://gems.github.com"
  #config.gem 'oauth', :version => '0.3.6'
  #config.gem 'mash', :version => '0.0.3'
  #config.gem 'httparty', :version => '0.4.3'
  #config.gem 'crack', :version => '0.1.2'
  #config.gem 'ruby-hmac', :version => '>= 0.3.2', :lib => 'hmac'
  #config.gem 'rubaidh-google_analytics', :lib => 'rubaidh/google_analytics', :source => 'http://gems.github.com'
  #config.gem 'grosser-rpx_now', :version => '>= 0.5.10', :lib => 'rpx_now', :source => 'http://gems.github.com'
  #config.gem 'factory_girl', :version => '1.2.3', :source => "http://gemcutter.org"
  #config.gem 'mocha', :version => '0.9.8'
  #config.gem 'seer', :version => '0.6.1'
  #config.gem 'version_info', :version => '0.7.1'

  # Only load the plugins named here, in the order given. By default, all plugins 
  # in vendor/plugins are loaded in alphabetical order.
  # :all can be used as a placeholder for all plugins not explicitly named
  # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

  # Add additional load paths for your own custom dirs
  # config.load_paths += %W( #{RAILS_ROOT}/extras )
  %w( mailers observers sweepers ).each do |s|
    config.autoload_paths += [ File.join(Rails.root, 'app', s) ]
  end

	# Rotate logs when they reach a size of 10M and keep no more than 10 of these
  #config.logger = Logger.new(config.log_path, 10, (1024**2)*10)

  # Force all environments to use the same logger level
  # (by default production uses :info, the others :debug)
  config.log_level = :debug

  # Make Time.zone default to the specified zone, and make Active Record store time values
  # in the database in UTC, and return them converted to the specified local zone.
  # Run "rake -D time" for a list of tasks for finding time zone names. Uncomment to use default local time.
  config.time_zone = 'UTC'

  # Your secret key for verifying cookie session data integrity.
  # If you change this key, all old sessions will become invalid!
  # Make sure the secret is at least 30 characters and all random, 
  # no regular words or you'll be exposed to dictionary attacks.
  #config.action_controller.session = {
  #  :session_key => '_trunk_session',
  #  :secret      => '78d3f88ecab89978876b7d923de6c9e2534611644d9b8a7aecff4eb56467b56d23847f5e968d7a56cefc0885ea50b738af7cf020f12a650d61df9f779abdd4fc'
  #}

  # Use the database for sessions instead of the cookie-based default,
  # which shouldn't be used to store highly confidential information
  # (create the session table with "rake db:sessions:create")
  config.action_controller.session_store = :active_record_store

  # Use SQL instead of Active Record's schema dumper when creating the test database.
  # This is necessary if your schema can't be completely dumped by the schema dumper,
  # like if you have constraints or database-specific column types
  # config.active_record.schema_format = :sql

  # Activate observers that should always be running
  config.active_record.observers = :annotation_observer
  
  # Use cronolog for log rotation in production
  # ROTATE_LOGS & CRONOLOG_PARAMS  constants
  # are set in config/preinitializer.rb
  # By default log rotation is switched off
  if ROTATE_LOGS && CRONOLOG_PARAMS
    config.logger       = Logger.new(IO.popen( CRONOLOG_PARAMS, "w" ))
    config.logger.level = Logger::DEBUG
  end
  
end

# Workaround critical XML parsing bug.
ActionController::Base.param_parsers.delete(Mime::XML)

# Code to handle the issue of unintential file descriptor sharing in Phusion Passenger.
# Ref: http://www.modrails.com/documentation/Users%20guide.html#_example_1_memcached_connection_sharing_harmful
# and: http://info.michael-simons.eu/2009/03/23/phusion-passenger-and-memcache-client-revisited/
begin
  if defined?(PhusionPassenger)
    PhusionPassenger.on_event(:starting_worker_process) do |forked|
      if forked
        # We're in smart spawning mode.
        # Reset caches..
        BioCatalogue::CacheHelper.reset_caches
      else
        # We're in conservative spawning mode. We don't need to do anything.
      end
    end
  end
# In case you're not running under Passenger (i.e. devmode with mongrel)
rescue NameError => error
end
