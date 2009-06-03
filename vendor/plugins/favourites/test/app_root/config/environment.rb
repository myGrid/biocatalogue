require 'config/boot'

Rails::Initializer.run do |config|
  config.cache_classes = false
  config.whiny_nils = true
  config.active_record.timestamped_migrations = false
end
