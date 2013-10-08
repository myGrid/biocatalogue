# BioCatalogue: lib/bio_catalogue/availability_check.rb
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

require 'libxml'
require 'uri'
require 'pp'

module BioCatalogue
  module AvailabilityCheck

    class SoapResponseParser
      attr_accessor :document

      def initialize(response_string)
        @document = nil
        unless response_string.nil?
          begin
            @document = LibXML::XML::Parser.string(response_string).parse
          rescue XML::Parser::ParseError => ex
            Rails.logger.error( "parse error #{ex}")
            @document = nil
          rescue Exception => ex
            Rails.logger.error( "ERROR: there was a problem parsing response string:" )
            Rails.logger.error( "#{ex}")
            @document = nil
          end
        end
      end

      # All soap faults are expected to be wrapped
      # in a soap envelope.
      def soap_fault?
        begin
          ns_prefix.each  do |prefix|
           if @document.find("/#{prefix}:Envelope").first
             return true
           end
          end
          return false
        rescue Exception => ex
          Rails.logger.error(ex)
          return false
        end
      end

      def ns_prefix
        prefixes = []
        unless @document.nil?
          @document.root.namespaces.each do |ns|
            prefixes << ns.prefix
          end
        end
        return prefixes
      end

      def dump
        pp @document
      end
    end

    class SoapFault
      attr_accessor :fault

      def initialize(url)
        @url    = url
        @fault  = get_response
      end

      def get_response(url = @url)
        @response = %x[curl --insecure --max-time 20 --header "Content-Type: text/xml" --data '<?xml version="1.0"?> ' #{url}]
        unless @response.length == 0
          return @response
        end
        return nil
      end
    end

    class SoapEndPoint
      attr_accessor :fault, :parser

      def initialize(url)
        @fault  = SoapFault.new(url).fault
        @parser = SoapResponseParser.new(@fault)
      end

      def available?
        begin

          return true if (@fault && @fault.split[0]== '<?xml')
          return true if (@parser &&  @parser.soap_fault?)
          return false
        rescue Exception => ex
          Rails.logger.error(ex)
          return false
        end
      end
    end

    class URLCheck
      attr_accessor :response

      def initialize(url)
        @url        = url
        @response   = nil
        @success    = ['200', '202', '204']
        @redirects  = ['300', '301', '302', '303', '307']
        @not_allwd  = ['405']
        @failure    = ['400', '404']
        @try_again  = ['500']
        @method     = 'HEAD'
        @try_others = ['OPTIONS', 'GET']
        get_response
      end

      def get_response(url = @url, method = @method)
        puts "Trying #{url} with #{method}."
        begin
          @response =  %x[curl -I --insecure --max-time 20 -X #{method} #{url}]
        rescue Exception => ex
          Rails.logger.error("problem occurred while accessing #{url}")
          Rails.logger.error(ex)
        end
      end

      def response_code
        @response.split[1]
      end

      def success?
        @success.include?(response_code)
      end

      def redirect?
        @redirects.include?(response_code)
      end

      def failure?
        @failure.include?(response_code)
      end

      def method_not_allowed?
        @not_allwd.include?(response_code)
      end

      def try_again?
        @response.blank? || @try_again.include?(response_code)
      end

      def follow_redirect(level=3)
        Rails.logger.info("Now following redirect. Max of #{level} redirects will be followed ")
        while level > 0 && redirect?
          @response = get_response(redirect_location) if redirect_location
          level = level - 1
        end
      end

      def try_again(methods = @try_others)
        return if methods.nil?

        puts "Trying methods other than #{@method} for #{@url}."
        methods.each do |method|
          @response = get_response(@url, method)
          return if success?
        end
      end

      def redirect_location
        if @response.split.index("Location:")
          uri = URI.parse(@response.split.fetch(@response.split.index("Location:") + 1 ))
          if uri.scheme == 'http' || uri.scheme == 'https'
            return uri
          end
        end
        return nil
      end

      def allowed_methods
        if @response.split.index("Allow:")
          methods = @response.split.fetch(@response.split.index("Allow:") + 1).split(',')

          result = []
          methods.each do |method|
            method.strip!
            result << method if @try_others.include? method
          end

          return result
        end
        return nil
      end

      def available?
        begin
          return true if success?
          return false if failure?
          follow_redirect if redirect?
          try_again(allowed_methods) if method_not_allowed?
          try_again if try_again?
          return success?
        rescue Exception => ex
          Rails.logger.error("problem occured while checking availability of a url")
          Rails.logger.error(ex)
          return false
        end
      end
    end
  end
end


