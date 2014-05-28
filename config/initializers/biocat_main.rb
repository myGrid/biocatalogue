# BioCatalogue: app/config/initializers/biocat_main.rb
#
# Copyright (c) 2008-2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details



# Set up loggers to STDOUT if in script/console 
# (so now things like SQL queries etc are shown in the console instead of the development/production/etc logs).
if "irb" == $0
  BioCatalogue::Util.say "Setting up IRB to log SQL queries etc"
  ActiveRecord::Base.logger = Logger.new(STDOUT)
end

module BioCatalogue
  include VersionInfo
  VERSION.file_name = File.expand_path("version_info.yml", ".")
  
  API_VERSION = "1.2.1"
end

# This is not loaded in Rails 2.3 anymore (apparently).
require 'net/smtp'

# Register the custom BioCatalogue "lite" API mime type
Mime::Type.register 'application/biocat-lite+json', :bljson

# Require additional libraries

require 'rpx_now/user_integration'
require 'delayed_job'
require 'array'
require 'object'
require 'string'
require 'hash'
require 'numeric'
require 'mime_type'
require 'addressable/uri'
require 'tabs_on_rails'
require 'libxml'
require 'dnsruby'
require 'open-uri'
require 'redcarpet'
require 'pp'
require 'rexml/document'
require 'acts_as_archived'

require 'exception_notifier'
require 'bio_catalogue/annotations/custom_migration_to_v3'

# NOTE: 
# all libraries within /lib/bio_catalogue will be loaded automatically by Rails (when accessed),
# as long as they follow the convention. E.g.: the module BioCatalogue::ActsAsHuman
# should be defined in the file /lib/bio_catalogue/acts_as_human.rb
#
# Some of these need to be preloaded...
require 'bio_catalogue/acts_as_service_versionified'
require 'bio_catalogue/has_submitter'
require 'bio_catalogue/annotations'
require 'bio_catalogue/annotations/extensions'
require 'bio_catalogue/monitoring'
require 'bio_catalogue/monitoring/status'

require 'bio_catalogue/util'
require 'bio_catalogue/categorising'

require 'bio_catalogue/cache_helper'
require 'oauth_authorize'

require 'bio_catalogue/resource'
require 'country_codes'

require 'will_paginate/array'

# Require all .rb files from lib/ directory
#Dir[File.join(File.dirname(__FILE__), '../../lib/**/*.rb')].each {|file| require file}

BioCatalogue::Util.say("Running in #{Rails.env} mode...")
BioCatalogue::Util.say("Configuring the #{SITE_NAME} application...")

# Never explicitly load the memcache-client library as we need to use 
# the specific one vendored in our codebase.
#NEVER DO:require 'memcache'

# Change XML backend that Rails uses to a faster one
ActiveSupport::XmlMini.backend = 'LibXML'

# Initialise the country codes library
CountryCodes

# Set up caches
#BioCatalogue::CacheHelper.setup_caches

# Load the up categories data into the DB if required
BioCatalogue::Categorising.load_data

# Configure addthis.com widget
if ENABLE_BOOKMARKING_WIDGET
  Jaap3::Addthis::CONFIG[:publisher] = ADDTHIS_USERNAME 
  Jaap3::Addthis::DEFAULT_OPTIONS[:secure] = true
end

# Set Google Analytics code
Rubaidh::GoogleAnalytics.tracker_id = GOOGLE_ANALYTICS_TRACKER_ID if ENABLE_GOOGLE_ANALYTICS

# Set RPX API key (for OpenID, Twitter, Facebook, etc logins - see https://rpxnow.com/)
if ENABLE_RPX
  RPXNow.api_key = RPX_API_KEY
end

# Set global pagination per_page parameter in all models.
PAGE_ITEMS_SIZE = 21
class ActiveRecord::Base
  cattr_reader :per_page
  @@per_page = PAGE_ITEMS_SIZE
end

MAX_PAGE_SIZE = 99


#  MAX_RESULTS is the total number of results to return.
# The reason it is being assigned to default_per_page is because instead of pulling each page of results
# one page at a time, we pull all pages at once so we can find all the associated models.
# We're making it pull one MASSIVE page of results.
MAX_RESULTS = 10000
Sunspot.config.pagination.default_per_page = MAX_RESULTS


# The amount of time to cache the metadata counts data.
METADATA_COUNTS_DATA_CACHE_TIME = 60*60  # 60 minutes, in seconds.

HOMEPAGE_ACTIVITY_FEED_ENTRIES_CACHE_TIME = 5*60  # 5 minutes, in seconds.

SEARCH_ITEMS_FROM_SOLR_CACHE_TIME = 30  # 30 seconds

BOT_IGNORE_LIST = "Googlebot",
                  "Slurp",
                  "Yahoo",
                  "msnbot",
                  "crawler",
                  "bot",
                  "heritrix",
                  "spider",
                  "Nutch",
                  "JMeter",
                  "test",
                  "Disqus"


# ================================
# Configure the Annotations plugin
# --------------------------------

# Remember that all attribute names specified MUST be in lowercase

# Disabled this due to ontological term URIs as tags...
#Annotations::Config.attribute_names_for_values_to_be_downcased.concat([ "tag" ])

Annotations::Config.strip_text_rules.update({ "tag" => [ '"', /^'/, /'$/ ] })

Annotations::Config.limits_per_source.update({ "rating.speed" => 1,
                                               "rating.reliability" => 1,
                                               "rating.ease-of-use" => 1,
                                               "rating.documentation" => 1 })

Annotations::Config.attribute_names_to_allow_duplicates.concat([ "tag",
                                                                 "rating.speed",
                                                                 "rating.reliability",
                                                                 "rating.ease-of-use",
                                                                 "rating.documentation" ])

Annotations::Config.content_restrictions.update({ "rating.documentation" => { :in => 1..5, :error_message => "Please provide a rating between 1 and 5" },
                                                  "test_xyz" => { :in => [ "fruit", "nut", "fibre" ], :error_message => "Please select a valid test_xyz" } })

Annotations::Config.default_attribute_identifier_template = ANNOTATION_ATTRIBUTE_DEFAULT_IDENTIFIER_TEMPLATE
Annotations::Config.attribute_name_transform_for_identifier = Proc.new { |name|
  regex = /\.|-|:/
  if name.match(regex)
    name.gsub(regex, ' ').titleize.gsub(' ', '_').camelize(:lower)
  else
    name.camelize(:lower)
  end
}

# Value factories...

tag_annotation_value_factory = Proc.new { |v|
  case v
    when String, Symbol
      namespace, term_keyword = BioCatalogue::Tags::split_ontology_term_uri(v.to_s)
      Tag.find_or_create_by_label_and_name(term_keyword, v.to_s)
    else
      v
  end
}

# "tag" annotations
Annotations::Config.value_factories["tag"] = tag_annotation_value_factory

# Legacy FETA annotations:
Annotations::Config.value_factories["<http://www.mygrid.org.uk/mygrid-moby-service#hasParameterType>".downcase] = tag_annotation_value_factory
Annotations::Config.value_factories["<http://www.mygrid.org.uk/mygrid-moby-service#inNamespaces>".downcase] = tag_annotation_value_factory
Annotations::Config.value_factories["<http://www.mygrid.org.uk/mygrid-moby-service#objectType>".downcase] = tag_annotation_value_factory
Annotations::Config.value_factories["<http://www.mygrid.org.uk/mygrid-moby-service#performsTask>".downcase] = tag_annotation_value_factory
Annotations::Config.value_factories["<http://www.mygrid.org.uk/mygrid-moby-service#usesMethod>".downcase] = tag_annotation_value_factory
Annotations::Config.value_factories["<http://www.mygrid.org.uk/mygrid-moby-service#usesResource>".downcase] = tag_annotation_value_factory

# "category" annotations
Annotations::Config.value_factories["category"] = Proc.new { |v|
  case v
    when String, Symbol, Numeric
      Category.find_by_id(v)
    else
      v
  end
}

# Value type validations...

Annotations::Config::valid_value_types["tag"] = "Tag"

Annotations::Config::valid_value_types["category"] = "Category"
    
# ================================


# ================================
# LEGACY!!!
# Ratings categories configuration
# --------------------------------

# These take the form:
# { rating_annotation_attribute_name => [ visible_name, help_text ] }

# IMPORTANT: remember to update any Annotations plugin configuration settings above when adding to this.

#SERVICE_RATINGS_CATEGORIES = { "rating.speed" => [ "Speed", "Rate how fast this service has been for you" ],
#                               "rating.reliability" => [ "Reliability", "Rate how reliable this service has been for you" ],
#                               "rating.ease-of-use" => [ "Ease of Use", "Rate how easy this service has been to use for you" ],
#                               "rating.documentation" => [ "Documentation",  "Rate the level and usefulness of documentation you feel this service has" ] }.freeze

SERVICE_RATINGS_CATEGORIES = { "rating.documentation" => [ "Documentation",  "Rate the level and usefulness of documentation you feel this service has" ] }.freeze
#===============================================================


# ===============================================================
# Configure global settings for the SuperExceptionNotifier plugin
# ---------------------------------------------------------------

#ExceptionNotifier::Notifier.send_email_error_codes = %W( 400 405 500 501 503 )

#ExceptionNotifier.view_path = 'app/views/error'

BioCatalogue::Application.config.middleware.use ExceptionNotifier,
                                                :email => {
                                                    :send_email_error_codes => %W( 400 405 500 501 503 ),
                                                    :view_path => 'app/views/error'
                                                }

Paperclip::Attachment.default_options[:path] = ':rails_root/app/assets/images/:url'
Paperclip::Attachment.default_options[:url] = ":class/#{Rails.env}/:id/:filename/:style.:extension"


# ===============================================================

WhiteListHelper.tags = %w(strong em b i p code pre tt output samp kbd var sub sup dfn cite big small address hr br div span h1 h2 h3 h4 h5 h6 ul ol li dt dd abbr acronym a img blockquote del ins fieldset legend table th td tr tbody)

# ===============================================================
# Configure global settings for the monitoring history
# ---------------------------------------------------------------

MONITORING_HISTORY_LIMIT = 5 unless defined?(MONITORING_HISTORY_LIMIT) 

SHOW_MONITORING_GRAPH = true unless defined?(SHOW_MONITORING_GRAPH)


