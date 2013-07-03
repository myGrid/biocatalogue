require 'rubygems'
require 'rake'
require 'net/http'
require 'active_record'

namespace :solr do

  desc 'Starts Solr. Options accepted: Rails.env=your_env, PORT=XX. Defaults to development if none.'
  task :start do
    require Rails.root.join("lib", "acts_as_solr", "config", "solr_environment" )
    begin
      n = Net::HTTP.new('127.0.0.1', SOLR_PORT)
      n.request_head('/').value 

    rescue Net::HTTPServerException #responding
      puts "Port #{SOLR_PORT} in use" and return

    rescue Errno::ECONNREFUSED, NoMethodError #not responding
      Dir.chdir(SOLR_PATH) do

        puts "java #{SOLR_JVM_OPTIONS} -Dsolr.data.dir=#{SOLR_DATA_PATH} -Djetty.logs=#{SOLR_LOGS_PATH} -Djetty.port=#{SOLR_PORT} -jar #{Rails.root.join("lib", "acts_as_solr", "solr", "start.jar")}"
        pid = fork do
          #STDERR.close
          exec "java #{SOLR_JVM_OPTIONS} -Dsolr.data.dir=#{SOLR_DATA_PATH} -Djetty.logs=#{SOLR_LOGS_PATH} -Djetty.port=#{SOLR_PORT} -jar #{Rails.root.join("lib", "acts_as_solr", "solr", "start.jar")}"
        end
        sleep(5)
        File.open("#{SOLR_PIDS_PATH}/#{Rails.env}_pid", "w"){ |f| f << pid}
        puts "#{Rails.env} Solr started successfully on #{SOLR_PORT}, pid: #{pid}."
      end
    end
  end
  
  desc 'Stops Solr. Specify the environment by using: Rails.env=your_env. Defaults to development if none.'
  task :stop do

    require Rails.root.join("lib", "acts_as_solr", "config", "solr_environment" )
    fork do
      file_path = "#{SOLR_PIDS_PATH}/#{Rails.env}_pid"
      puts "FILEPATH = #{file_path}"
      if File.exists?(file_path)
        File.open(file_path, "r") do |f| 
          pid = f.readline
          Process.kill('TERM', pid.to_i)
        end
        File.unlink(file_path)
        Rake::Task["solr:destroy_index"].invoke if Rails.env == 'test'
        puts "Solr shutdown successfully."
      else
        puts "PID file not found at #{file_path}. Either Solr is not running or no PID file was written."
      end
    end
  end
  
  desc 'Remove Solr index'
  task :destroy_index do
    require Rails.root.join("lib", "acts_as_solr", "config", "solr_environment" )
    raise "In production mode.  I'm not going to delete the index, sorry." if Rails.env == "production"
    if File.exists?("#{SOLR_DATA_PATH}")
      Dir["#{SOLR_DATA_PATH}/index/*"].each{|f| File.unlink(f)}
      Dir.rmdir("#{SOLR_DATA_PATH}/index")
      puts "Index files removed under " + Rails.env + " environment"
    end
  end
  
  # this task is by Henrik Nyh
  # http://henrik.nyh.se/2007/06/rake-task-to-reindex-models-for-acts_as_solr
  desc %{Reindexes data for all acts_as_solr models. Clears index first to get rid of orphaned records and optimizes index afterwards. Rails.env=your_env to set environment. ONLY=book,person,magazine to only reindex those models; EXCEPT=book,magazine to exclude those models. START_SERVER=true to solr:start before and solr:stop after. BATCH=123 to post/commit in batches of that size: default is 300. CLEAR=false to not clear the index first; OPTIMIZE=false to not optimize the index afterwards.}
  task :reindex => :environment do
    require Rails.root.join("lib", "acts_as_solr", "config", "solr_environment" )

    includes = env_array_to_constants('ONLY')
    if includes.empty?
      includes = Dir.glob("#{Rails.root}/app/models/*.rb").map { |path| File.basename(path, ".rb").camelize.constantize }
    end
    excludes = env_array_to_constants('EXCEPT')
    includes -= excludes
    
    optimize            = env_to_bool('OPTIMIZE',     true)
    start_server        = env_to_bool('START_SERVER', false)
    clear_first         = env_to_bool('CLEAR',       true)
    batch_size          = ENV['BATCH'].to_i.nonzero? || 100
    debug_output        = env_to_bool("DEBUG", false)

    ::Rails.logger.level = ActiveSupport::BufferedLogger::INFO unless debug_output

    if start_server
      puts "Starting Solr server..."
      Rake::Task["solr:start"].invoke 
    end
    
    # Disable solr_optimize
    module ActsAsSolr::CommonMethods
      def blank() end
      alias_method :deferred_solr_optimize, :solr_optimize
      alias_method :solr_optimize, :blank
    end
    
    models = includes.select { |m| m.respond_to?(:rebuild_solr_index) }    
    models.each do |model|
      
      # Added by Jits (2009-05-09):
      # Set to auto_commit to true just for this...
      model.configuration[:auto_commit] = true
  
      if clear_first
        puts "Clearing index for #{model}..."
        ActsAsSolr::Post.execute(Solr::Request::Delete.new(:query => "#{model.solr_configuration[:type_field]}:#{model}")) 
        ActsAsSolr::Post.execute(Solr::Request::Commit.new)
      end
      
      puts "Rebuilding index for #{model}..."
      model.rebuild_solr_index(batch_size)
      
      # Sleep for a bit to give Solr a chance to process... 
      sleep 2
      
    end 

    if models.empty?
      puts "There were no models to reindex."
    elsif optimize
      puts "Optimizing..."
      models.last.deferred_solr_optimize
    end

    if start_server
      puts "Shutting down Solr server..."
      Rake::Task["solr:stop"].invoke 
    end
    
  end
  
  def env_array_to_constants(env)
    env = ENV[env] || ''
    env.split(/\s*,\s*/).map { |m| m.singularize.camelize.constantize }.uniq
  end
  
  def env_to_bool(env, default)
    env = ENV[env] || ''
    case env
      when /^true$/i then true
      when /^false$/i then false
      else default
    end
  end

end

