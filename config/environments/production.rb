# Settings specified here will take precedence over those in config/environment.rb

# The production environment is meant for finished, "live" apps.
# Code is not reloaded between requests
config.cache_classes = true

# Use a different logger for distributed setups
# config.logger = SyslogLogger.new

# Full error reports are disabled and caching is turned on
config.action_controller.consider_all_requests_local = false
config.action_controller.perform_caching             = true

# Use a different cache store in production
# config.cache_store = :mem_cache_store

# Enable serving of images, stylesheets, and javascripts from an asset server
# config.action_controller.asset_host                  = "http://assets.example.com"

# Disable delivery errors, bad email addresses will be ignored
# config.action_mailer.raise_delivery_errors = false


# From: http://www.whatcodecraves.com/articles/2009/03/17/rails_2.2.2_chicken_and_egg_migrations_headache/ -

# kids, this is what an ugly hack looks like. Don't worry, Rails
# 2.3 will fix this.
config.cache_classes = (File.basename($0) == "rake" && !ARGV.grep(/db:/).empty?) ? false : true

