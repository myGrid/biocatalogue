# Settings specified here will take precedence over those in config/environment.rb

# The production environment is meant for finished, "live" apps.
# Code is not reloaded between requests
config.cache_classes = true

# Use a different logger for distributed setups
# config.logger = SyslogLogger.new

# Use cronolog for log rotation in production
# Set ROTATE_LOGS=false to turn off log rotation.
ROTATE_LOGS     = false
cronolog_params = "/my/server/cronolog /my/application/file/log/production.log.%Y%m%d"

if ROTATE_LOGS
  config.logger       = Logger.new(IO.popen( cronolog_params, "w" ))
  config.logger.level = Logger::INFO
end

# Full error reports are disabled and caching is turned on
config.action_controller.consider_all_requests_local = false
config.action_controller.perform_caching             = true

# Use a different cache store in production
# config.cache_store = :mem_cache_store

# Enable serving of images, stylesheets, and javascripts from an asset server
# config.action_controller.asset_host                  = "http://assets.example.com"

# Disable delivery errors, bad email addresses will be ignored
# config.action_mailer.raise_delivery_errors = false

config.action_view.cache_template_loading = true
