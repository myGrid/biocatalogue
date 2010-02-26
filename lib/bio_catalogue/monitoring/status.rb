# BioCatalogue: lib/bio_catalogue/monitoring/status.rb
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

module BioCatalogue
  module Monitoring
    class Status
      attr_accessor :message, 
                    :label,
                    :symbol_filename,
                    :small_symbol_filename,
                    :last_checked
      
      def initialize
        @message                  = ""
        @label                    = ""
        @symbol_filename          = ""
        @small_symbol_filename    = ""
        @last_checked             = nil
      end
    end
    
    class TestResultStatus < Status
      attr_accessor :test_result
      
      def initialize(test_result)
        super()
        @test_result = test_result
        populate
      end
      
      def populate
        case @test_result.result
          when 0
            @message                = "This check was successful"
            @label                  = "Success"
            @symbol_filename        = "tick-sphere-50.png"
            @small_symbol_filename  = "small-tick-sphere-50.png"
          when 1
            @message                = "This check failed"
            @label                  = "Fail"
            @symbol_filename        = "cross-sphere-50.png"
            @small_symbol_filename  = "small-cross-sphere-50.png"
          when 2..255
            @message                = "Something did not go right with this check"
            @label                  = "Warning"
            @symbol_filename        = "pling-sphere-50.png"
            @small_symbol_filename  = "small-pling-sphere-50.png"
          when -1
            @message                = "This check has not been run yet"
            @label                  = "Unchecked"
            @symbol_filename        = "query-sphere-50.png"
            @small_symbol_filename  = "small-query-sphere-50.png"
          else
            @message = "Test status is unknown"
        end
        
        @last_checked = @test_result.created_at
      end
      
    end
    
    class ServiceTestStatus < Status
      attr_accessor :service_test
      
      def initialize(service_test)
        super()
        @service_test = service_test
        populate
      end
      
      def populate
        case @service_test.latest_test_result.result
          when 0
            @message                = "The last check for this test was successful"
            @label                  = "Success"
            @symbol_filename        = "tick-sphere-50.png"
            @small_symbol_filename  = "small-tick-sphere-50.png"
          when 1
            @message                = "The last check failed"
            @label                  = "Fail"
            @symbol_filename        = "cross-sphere-50.png"
            @small_symbol_filename  = "small-cross-sphere-50.png"
          when 2..255
            @message                = "Something did not quite go right with the last check for this test"
            @label                  = "Warning"
            @symbol_filename        = "pling-sphere-50.png"
            @small_symbol_filename  = "small-pling-sphere-50.png"
          when -1
            @message                = "This test has not run yet"
            @label                  = "Unchecked"
            @symbol_filename        = "query-sphere-50.png"
            @small_symbol_filename  = "small-query-sphere-50.png"
          else
            @message = "Test status is unknown"
        end
        
        @last_checked = @service_test.latest_test_result.created_at
      end
      
    end
    
    class ServiceStatus < Status
      attr_accessor :service
                    
      def initialize(service)
        super()
        @service = service
        populate
      end
      
      # To calculate the overall status of a service, the following algorithm is used:
      # 1 Ignore all ServiceTests NOT run by the BioCatalogue
      # 2 For all ServiceTests that are run by the BioCatalogue, go through the latest TestResults
      # 3 If there are none, status is "blue" meaning unchecked
      # 4 If at least one has failed, status is "amber" and relevant failure messages should be appended to the overall status message
      # 5 If all tests pass then status is "green"
      def populate
        result_code = -1
        
        test_results = @service.service_tests.map{|st| st.latest_test_result if BioCatalogue::Monitoring::INTERNAL_TEST_TYPES.include?(st.test_type)}.compact
        
        unless test_results.empty?
          test_results.each do |test_result|
            unless test_result.result == -1 
              @last_checked.nil? ? @last_checked = test_result.created_at : (@last_checked = test_result.created_at if @last_checked < test_result.created_at)
            end
          end
        end
        
        failed = test_results.map{|r| r if r.result > 0}.compact
        
        if failed.empty?
          test_results.each{|r| result_code = 0 if r.result == 0}
        else
          result_code = failed[0].result
        end
        
        case result_code 
          when 0
            @message                  = "All tests were successful for this service"
            @label                    = "Success"
            @symbol_filename          = "tick-sphere-50.png"
            @small_symbol_filename    = "small-tick-sphere-50.png"
          when 1..255
            @message                  = failure_message(failed) # more info from tests causing problems
            @label                    = "Warning"
            @symbol_filename          = "pling-sphere-50.png"
            @small_symbol_filename    = "small-pling-sphere-50.png"
          when -1
            @message                  = "No tests have been run yet for this service"
            @label                    = "Unchecked"
            @symbol_filename          = "query-sphere-50.png"
            @small_symbol_filename    = "small-query-sphere-50.png"
          else
            @message = "Service status is unknown"
        end 
      end
      
      # only takes into account test scripts &
      # url checks
      # TODO : handle other kinds of tests
      def failure_message(failure_results=[])
        msg = "Some or all of the tests for this service did not succeed"
        msg += "<p><ul>"
        url_tests    = failure_results.collect{|r| r if r.service_test.test_type =='UrlMonitor'}.compact
        test_scripts = failure_results.collect{|r| r if r.service_test.test_type =='TestScript'}.compact
        
        url_tests.each do |t|
          msg +="<li> Could not access <b>#{t.service_test.test.property} </b>.</li>\n"
        end
        
        test_scripts.each do |t|
          msg +="<li> Test Script: <b>#{t.service_test.test.name} </b> failed.</li>\n"
        end
        msg +="</ul></p>" 
        
        return msg
      end
    end
  end
end