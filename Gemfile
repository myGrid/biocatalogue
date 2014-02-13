source "https://rubygems.org"

ruby "1.9.3"

gem "rails", "~>3.2.14"
gem "rdoc", "~>3.4"
gem "rake"

gem "mysql2"
gem "mail"#, "2.5.3" # latest version won't send emails
gem "rails_autolink"
gem "solr-ruby"
gem "json"
gem "addressable"
gem "daemons"
gem "dnsruby"
gem 'libxml-ruby',"2.6.0",:require => "libxml"

# For use in reading ontologies in
gem 'linkeddata'
gem 'equivalent-xml'

#Mongrel broken for 1.9.3. Using thin as suggested here
# http://stackoverflow.com/questions/13851741/install-mongrel-in-ruby-1-9-3
#gem "mongrel"
gem 'thin'
gem 'rubyzip'
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
#Soap4r not supported on r1.9 so using a branch
#gem "soap4r"
gem 'mumboe-soap4r'
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
gem 'prototype-rails'
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

gem "tabs_on_rails"

gem "haml"
gem "hashie"

# sunspot_rails has nokogiri as a dependancy and Nokogiri 1.6.0 uses r1.9
# so we need to install this specific version here
gem 'nokogiri', '~>1.5.10'
gem 'sunspot_rails'
gem 'sunspot_solr'
gem 'progress_bar'

# Not used - disabled in config/initializers/biocat_local.rb
#gem "onyx-cache-money", "0.2.6.1", :require => "cache_money", :path => "vendor/gems/onyx-cache-money-0.2.6.1"
#gem "cache-money" #not sure how to test 

# Frozen gems
#New version_info requires ruby > 1.9.*  - leave frozen till Rails 3 upgrade
gem "version_info", "0.7.1", :path => "vendor/gems/version_info-0.7.1"

gem 'sass-rails',   '~> 3.2.3'
group :assets do
  gem 'coffee-rails', '~> 3.2.1'
  gem 'uglifier', '>= 1.0.3'
end

