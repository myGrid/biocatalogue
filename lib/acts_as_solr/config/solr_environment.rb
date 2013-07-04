# Rails.root isn't defined yet, so figure it out.
rails_root_dir = Rails.root.to_s
SOLR_PATH = "#{File.dirname(File.expand_path(__FILE__))}/../solr" unless defined? SOLR_PATH

SOLR_LOGS_PATH = "#{rails_root_dir}/log" unless defined? SOLR_LOGS_PATH
SOLR_PIDS_PATH = "#{rails_root_dir}/tmp/pids" unless defined? SOLR_PIDS_PATH
SOLR_DATA_PATH = "#{rails_root_dir}/solr/#{Rails.env}" unless defined? SOLR_DATA_PATH

unless defined? SOLR_PORT
  config = YAML::load_file(rails_root_dir+'/config/solr.yml')
  SOLR_PORT = ENV['PORT'] || URI.parse(config[Rails.env]['url']).port
end

SOLR_JVM_OPTIONS = config[Rails.env]['jvm_options'] unless defined? SOLR_JVM_OPTIONS

if Rails.env.test?
  DB = (ENV['DB'] ? ENV['DB'] : 'mysql') unless defined?(DB)
  MYSQL_USER = (ENV['MYSQL_USER'].nil? ? 'root' : ENV['MYSQL_USER']) unless defined? MYSQL_USER
  require File.join(File.dirname(File.expand_path(__FILE__)), '..', 'test', 'db', 'connections', DB, 'connection.rb')
end
