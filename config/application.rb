require File.expand_path('../boot', __FILE__)

#Configurations needed before the app init

require 'csv'
require 'rails/all'
if defined?(Bundler)
  # If you precompile assets before deploying to production, use this line
  Bundler.require(*Rails.groups(:assets => %w(development test)))
  # If you want your assets lazily compiled in production, use this line
  # Bundler.require(:default, :assets, Rails.env)
end

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


    # ============================================
    # Configure the Exception Notification plugin:
    # --------------------------------------------

    # include ExceptionNotifiable

    # This line ensures that templates and mailing is enabled for the Exception Notification plugin
    # on your local development set up (so as to test the templates etc).
    # Note: error templates will only show in production mode.
    #
    # Be aware of this when configuring the email settings in biocat_local.rb -
    # in most cases you should disable email sending in your development setup
    # (see config/initializers/mail.rb.pre for more info).
    #local_addresses.clear # always send email notifications instead of displaying the error
    #
    #self.rails_error_classes = {
    #  ActiveRecord::RecordNotFound => "404",
    #  ::ActionController::UnknownController => "406",
    #  ::ActionController::UnknownAction => "406",
    #  ::ActionController::RoutingError => "406",
    #  ::ActionView::MissingTemplate => "406",
    #  ::ActionView::TemplateError => "500"
    #}
    #
    #self.error_layout = "application_error"

    config.middleware.use ExceptionNotifier,
                          :local_addresses => :clear,
                          :rails_error_classes => {
                              ActiveRecord::RecordNotFound => "404",
                              ::ActionController::UnknownController => "406",
                              ::AbstractController::ActionNotFound => "406",
                              ::ActionController::RoutingError => "406",
                              ::ActionView::MissingTemplate => "406",
                              ::ActionView::TemplateError => "500"
                          },
                          :error_layout  => "application_error"

    # ============================================


    # Enable the asset pipeline
    config.assets.enabled = true

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