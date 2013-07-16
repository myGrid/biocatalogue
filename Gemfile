source "https://rubygems.org"

ruby "1.8.7"

gem "rails", "~>3.2.13"
gem "rdoc", "~>3.4"
gem "rake"

gem "mysql2"
gem "mail", "2.5.3" # latest version won't send emails
gem "rails_autolink"
gem "solr-ruby"
gem "json"
gem "addressable"
gem "daemons"
gem "dnsruby"
gem "SystemTimer"
gem 'libxml-ruby',"2.6.0",:require => "libxml"
gem "mongrel"
gem "tzinfo"
gem "crack"
gem "factory_girl", "<=2.6.5"
gem "factory_girl_rails", "<4.0"
gem "geokit"
gem "rpx_now"
gem "httparty"
gem "mash"
gem "twitter"
gem "memcache-client", :require => "memcache"
gem "ruby-hmac"
gem "seer"
gem "soap4r"
gem "google_analytics"
gem "oauth-plugin"
gem "validates_existence"
gem 'delayed_job_active_record'
gem 'markaby'
#gem "validates_url_format_of"  # incompatible with Rails 3
gem "acts_as_trashable"
gem "my_annotations", :git => 'git://github.com/myGrid/annotations.git'
gem "will_paginate"
gem "better_logging"
gem "exception_notification", "<4.0.0", :require => 'exception_notifier'
gem 'prototype-rails', :git => 'git://github.com/rails/prototype-rails.git'
gem 'country-select'
gem 'validates_email_format_of' # Replaces validates_email_veracity_of
gem "dalli"

group :test do
# gem "webmock"
  gem 'shoulda', '<3.2.0'
end

#Linked to SysMO Git repositories
gem 'redbox', :git=>"git://github.com/SysMO-DB/redbox"
#gem 'redbox', :path => "vendor/gems/redbox"

gem "white_list", :git=>"https://github.com/neubloc/white_list.git"

# Not used - disabled in config/initializers/biocat_local.rb
#gem "onyx-cache-money", "0.2.6.1", :require => "cache_money", :path => "vendor/gems/onyx-cache-money-0.2.6.1"
#gem "cache-money" #not sure how to test 

# Frozen gems
#New version_info requires ruby > 1.9.*  - leave frozen till Rails 3 upgrade
gem "version_info", "0.7.1", :path => "vendor/gems/version_info-0.7.1"

