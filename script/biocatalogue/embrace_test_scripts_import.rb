#!/usr/bin/env ruby

# This script imports the test scripts data from the EMBRACE registry
# database into the Biocatalogue database. The scripts goes through 
# the services in the EMBRACE registry database and finds the one that 
# have test scripts associated with them. For each of the services with
# test script data, if a corresponding service is found in BioCatalogue, 
# then the script is imported.

# For SOAP services, corresponding services are those with the same wsdl url
# while for REST, corresponding services have the same Endpoint.

# requirements
# 1 - Access to an instance of the embrace registry DB
# 2 - Fill in the database setting as required by the script (bottom of script)
# Example
# db_config = { :host    => 'host name',
#              :user     => 'db user',
#              :password => 'password',
#              :database => 'database'}

# Important tables in the embrace services db include:
#
# a) The Services Table( DE_ws_Service)
#   +----------------+------------------+------+-----+---------+-------+
#   | Field          | Type             | Null | Key | Default | Extra |
#   +----------------+------------------+------+-----+---------+-------+
#   | nid            | int(10) unsigned | NO   | PRI | 0       |       | 
#   | version        | varchar(64)      | YES  |     | NULL    |       | 
#   | url            | text             | YES  |     | NULL    |       | 
#   | wsdl_url       | text             | YES  |     | NULL    |       | 
#   | das_url        | text             | YES  |     | NULL    |       | 
#   | rest_url       | text             | YES  |     | NULL    |       | 
#   | service_status | int(11)          | NO   |     | NULL    |       | 
#   | isdeleted      | tinyint(4)       | NO   |     | 0       |       | 
#   | datedeleted    | datetime         | YES  |     | NULL    |       | 
#   +----------------+------------------+------+-----+---------+-------+

# b) The Test Scripts Table (DE_ws_tests)

##     +----------------+------------------+------+-----+---------+-------+
#      | Field          | Type             | Null | Key | Default | Extra |
#      +----------------+------------------+------+-----+---------+-------+
#      | nid            | int(10) unsigned | NO   | PRI | 0       |       | 
#      | snid           | int(10) unsigned | NO   |     | 0       |       | 
#      | type_id        | int(10) unsigned | NO   |     | 0       |       | 
#      | locality_id    | int(10) unsigned | NO   |     | 0       |       | 
#      | binding_id     | int(10) unsigned | NO   |     | 0       |       | 
#      | sample_request | text             | YES  |     | NULL    |       | 
#      | package        | longblob         | YES  |     | NULL    |       | 
#      | operation      | text             | YES  |     | NULL    |       | 
#      | test_status    | int(11)          | NO   |     | NULL    |       | 
#      | isrunning      | tinyint(4)       | NO   |     | 0       |       | 
#      | daterunning    | datetime         | YES  |     | NULL    |       | 
#      | isdeleted      | tinyint(4)       | NO   |     | 0       |       | 
#      | datedeleted    | datetime         | YES  |     | NULL    |       | 
#      | pseudo         | tinyint(1)       | NO   |     | 0       |       | 
#      | wsdl_operation | varchar(256)     | NO   |     | NULL    |       | 
#      +----------------+------------------+------+-----+---------+-------+
#
# c) DE_node and DE_node_revisions tables.
#    These two tables contain the title and description of the test.
#    DE_node.title, DE_node_revisions.body
#
#TODO : tests script should be attributed to the user from EMBRACE, not the submitter in BioCatalogue

# Usage :
#   runs script on biocatalogue development database using these arguments for embrace DB
#   ruby script/biocatalogue/embrace_test_scripts_import.rb --environment=<env> --host=<host> --port=<port> --user=<user> --database=<db> --password=<password> 


require 'rubygems'
require "mysql2"
require "pp"
#require 'yaml'
require 'optparse'

module Embrace
  module TestScripts
    class Statistics
      attr_accessor :counts
      
      def initialize
        @counts = {:soap_services                 => 0,
                    :services_not_found_scripts   => 0,
                    :rest_services                => 0,
                    :success_script_imports       => 0,
                    :failed_script_imports        => 0,
                    :existing                     => 0
                    }
      end
      #dump the statistics of the import
      def dump
        puts "*************************************************************************************"
        puts "                          Summary Results"
        puts "\n\n"
        puts " No of Soap Services found        : #{@counts[:soap_services]}"
        puts " No of Rest Services found        : #{@counts[:rest_services]}"
        puts " No of successful script imports  : #{@counts[:success_script_imports]}"
        puts " No of failed script imports      : #{@counts[:failed_script_imports]}"
        puts " No of scripts from services not found    : #{@counts[:services_not_found_scripts]}"
        puts " No of script that were already imported  : #{@counts[:existing]}"
        puts "*************************************************************************************"
      end
      
    end
    
    module Importer
      
      @stats = Statistics.new
      # return a connection to the database
      def self.db_connection(host, user, password, database, port)
        return Mysql::new(host, user, password, database, port)
      end
      
      # Get active scripts from the DB      
      def self.embrace_test_scripts(conn)
        statement = "SELECT * FROM DE_ws_test WHERE isdeleted=0 AND operation IS NOT NULL LIMIT 1 "    
        conn.query(statement)
      end
      
      def self.embrace_soap_services(conn)
        statement  = "SELECT * FROM DE_ws_service WHERE isdeleted=0 "
        statement += "AND wsdl_url IS NOT NULL "
        conn.query(statement)
      end
      
      def self.embrace_rest_services(conn)
        statement = "SELECT * FROM DE_ws_service WHERE isdeleted=0 AND rest_url IS NOT NULL"
        conn.query(statement)
      end
      
      def self.service_for_test(test_id, conn)
        statement = "SELECT * FROM DE_ws_service WHERE nid=#{test_id}"
        conn.query(statement)
      end
      
      def self.test_scritpts_for_service(service_id, conn)
        statement = "SELECT * FROM DE_ws_test WHERE snid=#{service_id} AND isdeleted=0 "
        conn.query(statement)
      end
      
      def self.test_binding(id, conn)
        statement = "SELECT * FROM DE_ws_bindings WHERE binding_id=#{id} "
        conn.query(statement)
      end
      
      def self.test_description(id, conn)
        statement  = "SELECT DE_node.title, DE_node_revisions.body from DE_node, DE_node_revisions "
        statement += "WHERE DE_node_revisions.nid=#{id}  AND DE_node.nid=#{id}"
        conn.query(statement)
      end
      
      def self.get_user_email(test_id, conn)
        statement  = "SELECT DE_users.mail FROM DE_users, DE_node WHERE "
        statement += "DE_node.nid=#{test_id} AND DE_node.uid = DE_users.uid AND DE_node.type='webservicetest'"
        result = conn.query(statement)
        unless result.num_rows != 1
          result.each do |email|
            return email[0]
          end
        end
        return nil
      end
        
      def self.process_soap_services(conn)
        # check if the service exists
        # if it exists, add the test data to it
        # otherwise, jump to the next service
        services = embrace_soap_services(conn)
        services.each do |service|
          puts "==================================================================================="
          id      = service[0]
          version = service[1]
          url     = service[2]
          wsdl_url= service[3]
          das_url = service[4]
          rest_url= service[5]
          service_status = service[6]
          unless wsdl_url.strip.blank?
            begin
              @stats.counts[:soap_services] +=1 
              wsdl_url = Addressable::URI.parse(wsdl_url).normalize.to_s
              if (existing_service = SoapService.check_duplicate(wsdl_url, "")).nil?
                # service not available in BioCatalogue
                # nothing to do
                puts "INFO: Embrace Service with ID #{id} not found in BioCatalogue"
                @stats.counts[:services_not_found_scripts] += test_scritpts_for_service(id,conn).num_rows
              else
                puts "INFO: existing matching service found (ID: #{existing_service.id}, WSDL URL: '#{wsdl_url}')."
                tests = test_scritpts_for_service(id,conn)
                puts "INFO: Embrace Service with ID #{id} has #{tests.num_rows} tests"
                if tests.num_rows > 0
                  puts "INFO: creating test in BioCatalogue"
                  tests.each do |script|
                    if create_biocat_test_script(script, existing_service, conn)
                      puts "INFO: Created a new test script in BioCatalogue"
                    end
                  end
                end
              end
            rescue Exception => ex
              puts "ERROR: There were problems importing this script data"
              puts ex.backtrace
            end
          end
          puts "==================================================================================="
        end
      end
      
      def self.process_rest_services(conn)
        services = embrace_rest_services(conn)
        services.each do |service|
          id      = service[0]
          version = service[1]
          url     = service[2]
          wsdl_url= service[3]
          das_url = service[4]
          rest_url= service[5]
          service_status = service[6]
          unless rest_url.strip.blank?
            begin
              @stats.counts[:rest_services] +=1 
              puts "INFO: Embrace Service with ID #{id} has rest_url :  #{rest_url} "
              endpoint = Addressable::URI.parse(rest_url).normalize.to_s unless endpoint.blank?
              unless endpoint.nil?
                if (existing_service = RestService.check_duplicate(endpoint)).nil?
                  puts "INFO: Service does not exist in BioCatalogue"  
                  @stats.counts[:services_not_found_scripts] += test_scritpts_for_service(id,conn).num_rows
                else
                  tests = test_scripts_for_service(id,conn)
                  puts "INFO: Embrace Service with ID #{id} has #{tests.num_rows} tests"
                  tests.each do |script|
                    create_biocat_test_script(script, existing_service, conn)
                  end
                end
              end
            rescue Exception => ex
              @stats.counts[:failed_script_imports] += test_scritpts_for_service(id,conn).num_rows
              puts "ERROR: There were problems importing this script data"
              puts ex.backtrace
            end
          end
        end
        
      end
      
      #@script is an order list of the field values from DE_ws_test table
      # the package field must be valid (not NULL) as the data are expected
      # to be in that field
      # script is an array of values representing a row of the embrace DE_ws_test table
      # 
      ##+----------------+------------------+------+-----+---------+-------+---------------------------+
      # | Field          | Type             | Null | Key | Default | Extra |comment                    |
      # +----------------+------------------+------+-----+---------+-------+---------------------------+
      # | nid            | int(10) unsigned | NO   | PRI | 0       |       | node id=test_id           |
      # | snid           | int(10) unsigned | NO   |     | 0       |       | service id                |
      # | type_id        | int(10) unsigned | NO   |     | 0       |       | type of service id        |
      # | locality_id    | int(10) unsigned | NO   |     | 0       |       |                           |
      # | binding_id     | int(10) unsigned | NO   |     | 0       |       | programming language id   |
      # | sample_request | text             | YES  |     | NULL    |       |                           |
      # | package        | longblob         | YES  |     | NULL    |       | test script data          |
      # | operation      | text             | YES  |     | NULL    |       | test script executable    |
      # | test_status    | int(11)          | NO   |     | NULL    |       |                           |
      # | isrunning      | tinyint(4)       | NO   |     | 0       |       |                           |
      # | daterunning    | datetime         | YES  |     | NULL    |       |                           |
      # | isdeleted      | tinyint(4)       | NO   |     | 0       |       |                           |
      # | datedeleted    | datetime         | YES  |     | NULL    |       |                           |
      # | pseudo         | tinyint(1)       | NO   |     | 0       |       |                           |
      # | wsdl_operation | varchar(256)     | NO   |     | NULL    |       |                           |
      # +----------------+------------------+------+-----+---------+-------+ --------------------------+
      def self.create_biocat_test_script(script, existing_service, db)
        if already_imported?(script[0])
          puts "This script is already imported. Doing nothing..."
          @stats.counts[:existing] +=1 
          return
        end
        if script[6].nil?                              
          puts "Content for this script could not be obtained from the database."
          puts "ERROR : The 'package' field does not seem to contain any data..."
          @stats.counts[:failed_script_imports] +=1  
          return
        else
          user_email = get_user_email(script[0], db)
          
          user = User.find_by_email(user_email) || existing_service.submitter.id
       
          descs = test_description(script[0], db)
          name = ""
          description =" "
          descs.each  do |desc|
            name        = desc[0]
            description = desc[1]
            #description = 'No description found for this test' if description.nil? || description ==''
          end
          binding = test_binding(script[4], db).fetch_row[1]
          a_test  = TestScript.new(:name         => name,
                                  :exec_name     => script[7],
                                  :prog_language => binding.to_s.downcase,
                                  :submitter_id  => user.id
                                  )
          
           a_test.content_blob = ContentBlob.new({:data => script[6]})
           a_test.filename     = 'package.zip'
           a_test.content_type = 'application/zip'
           a_test.description  = description 
           a_test.service_id   = existing_service.id
           begin
              if a_test.save!
                @stats.counts[:success_script_imports] +=1                                                 
                relationship = Relationship.new(:subject_type => a_test.service_test.class.name,
                                                    :subject_id   => a_test.service_test.id,
                                                    :predicate    => 'BioCatalogue:sameAs',
                                                    :object_type  => 'EmbraceTest',
                                                    :object_id    => script[0])
                relationship.save(false)
              end
          rescue Exception => ex
            @stats.counts[:failed_script_imports] +=1 
            a_test.errors.full_messages.each do |msg|
              puts "ERROR: #{msg}"
            end
            #puts ex.backtrace
            return false
           end
          end
        end
        
        def self.already_imported?(test_id)
         hist = Relationship.first(:conditions => {:object_id => test_id, :object_type => 'EmbraceTest'} )
         unless hist.nil?
           return true
         end
         false
        end
        
        def self.run(*params)
          puts "EMBRACE Test Scripts Import "
          
          db_config = params.extract_options!.symbolize_keys
          db    = db_connection(db_config[:host], 
                                db_config[:user], 
                                db_config[:password], 
                                db_config[:database],
                                db_config[:port].to_i)
          process_soap_services(db)
          process_rest_services(db)
          puts "\nDone"
          @stats.dump
        end
      
    end
  end
end

# Execution
#-------------------------------------------------------------------------------
#env = "development"
#
#unless ARGV[0].nil? or ARGV[0] == ''
#  env = ARGV[0]
#end



# Configurations to be passed as command line arguments
# Defaults
config = { :environment =>'development',
           :host        => nil,
           :user        => nil,
           :password    => nil,
           :database    => nil,
           :port        => nil
             }

ARGV.options do |opt|
  script_name = File.basename($0)
  opt.on("-e", "--environment=[environment]", String, "rails environment", "Default: #{config[:environment]}"){|config[:environment]|}
  opt.on("-h", "--host=[host]", String, "database host", "Default: #{config[:host]}"){|config[:host]|}
  opt.on("-P", "--port=[port]", String, "database port", "Default: #{config[:port]}"){|config[:port]|}
  opt.on("-d", "--database=[database]", String, "database name", "Default: #{config[:database]}"){|config[:database]|}
  opt.on("-u", "--user=[user]", String, "user name", "Default: #{config[:user]}"){|config[:user]|}
  opt.on("-p", "--password=[password]", String, "database host", "Default: #{config[:host]}"){|config[:password]|}
  opt.parse!
end

RAILS_ENV = config[:environment]

if config.values.include?(nil)
  puts "Warning!!!"
  puts "\nSome EMBRACE DB setting are empty!. Current settings are:"
  pp config
  puts "\nYou may need to pass those as command line arguments..."
  puts "ruby script/biocatalogue/embrace_test_scripts_import.rb --environment=<env> --host=<host> --port=<port> --user=<user> --database=<db> --password=<password>"
  puts "Now Exiting ..."
  exit(0)
end

require File.join(File.dirname(__FILE__),'..','..', 'config', 'environment')

# Redirect $stdout to log file
puts "Redirecting output of $stdout to log file: '{Rails.root}/log/embrace_test_scripts_import_{current_time}.log' ..."
$stdout = File.new(File.join(File.dirname(__FILE__), '..', '..', 'log', "embrace_test_scripts_import_#{Time.now.strftime('%Y%m%d-%H%M')}.log"), "w")
$stdout.sync = true

Embrace::TestScripts::Importer.run(config)

# Reset $stdout
$stdout = STDOUT


