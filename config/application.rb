require File.expand_path('../boot', __FILE__)

#begin
#  require "rubygems"
#  require "bundler"
#rescue LoadError
#  raise "Could not load the bundler gem. Install it with `gem install bundler`."
#end
#
#if Gem::Version.new(Bundler::VERSION) <= Gem::Version.new("0.9.24")
#  raise RuntimeError, "Your bundler version is too old for Rails 2.3." +
#      "Run `gem install bundler` to upgrade."
#end
#
#begin
#  # Set up load paths for all bundled gems
#  ENV["BUNDLE_GEMFILE"] = File.expand_path("../../Gemfile", __FILE__)
#  Bundler.setup
#rescue Bundler::GemNotFound
#  raise RuntimeError, "Bundler couldn't find some gems." +
#      "Did you run `bundle install`?"
#end

#Configurations needed before the app init

# Logs rotation
#
# Set this to true to rotate the logs
ROTATE_LOGS = false

#
# Set the rotation parameters
# Example CRONOLOG_PARAMS = "/my/server/cronolog /my/application/file/log/production.log.%Y%m%d"
CRONOLOG_PARAMS = nil

require 'rails/all'

# If you have a Gemfile, require the gems listed there, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(:default, Rails.env) if defined?(Bundler)

module BioCatalogue
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Custom directories with classes and modules you want to be autoloadable.
    # config.autoload_paths += %W(#{config.root}/extras)
    config.autoload_paths += %W(#{config.root}/lib)

    # Only load the plugins named here, in the order given (default is alphabetical).
    # :all can be used as a placeholder for all plugins not explicitly named.
    # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

    # Activate observers that should always be running.
    # config.active_record.observers = :cacher, :garbage_collector, :forum_observer

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # JavaScript files you want as :defaults (application.js is always included).
    # config.action_view.javascript_expansions[:defaults] = %w(jquery rails)

    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = "utf-8"

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:password]

    # Only load the plugins named here, in the order given. By default, all plugins
    # in vendor/plugins are loaded in alphabetical order.
    # :all can be used as a placeholder for all plugins not explicitly named
    # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

    # Add additional load paths for your own custom dirs
    # config.load_paths += %W( #{RAILS_ROOT}/extras )
    %w( mailers observers sweepers ).each do |s|
      config.autoload_paths += [File.join(Rails.root, 'app', s)]
    end

    # Rotate logs when they reach a size of 10M and keep no more than 10 of these
    #config.logger = Logger.new(config.log_path, 10, (1024**2)*10)

    # Use cronolog for log rotation in production
    # ROTATE_LOGS & CRONOLOG_PARAMS constants
    # are set in config/preinitializer.rb
    # By default log rotation is switched off
    if ROTATE_LOGS && CRONOLOG_PARAMS
      config.logger = Logger.new(IO.popen(CRONOLOG_PARAMS, "w"))
      config.logger.level = Logger::DEBUG
    end

    # Force all environments to use the same logger level
    # (by default production uses :info, the others :debug)
    config.log_level = :debug

    # Make Time.zone default to the specified zone, and make Active Record store time values
    # in the database in UTC, and return them converted to the specified local zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Uncomment to use default local time.
    config.time_zone = 'UTC'

    # Use SQL instead of Active Record's schema dumper when creating the test database.
    # This is necessary if your schema can't be completely dumped by the schema dumper,
    # like if you have constraints or database-specific column types
    # config.active_record.schema_format = :sql

    # Activate observers that should always be running
    config.active_record.observers = :annotation_observer
  end
end

# Workaround critical XML parsing bug.
# ActionController::Base.param_parsers.delete(Mime::XML)

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
