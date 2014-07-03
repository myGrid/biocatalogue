# BioCatalogue: lib/bio_catalogue/wsdl_parser.rb
#
# Copyright (c) 2008-2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# This handles all WSDL parsing needs in the system.
# If a connection to a WSDLUtils service is available (see vendor/wsdl-parsing-service/) then it will use that for parsing,
# otherwise (and also in cases of parsing failures) it will fallback to the old WSDL parser that was initially implemented.

module BioCatalogue
  module WsdlParser

    # Parses a WSDL and returns back information that is useful for further processing.
    #
    # This method takes a URL to a WSDL file and returns back the following array:
    # [ service_info, error_messages, wsdl_file_contents ]
    # 
    # where:
    # - service_info: the information about the service in a structured, hierarchical form (see below). This is an empty Hash if breaking errors occurred.
    # - error_messages: collection (Array) of error messages that may have been raised during parsing (these are the breaking errors that most likely caused parsing to fail).
    # - wsdl_file_contents: the contents of the actual WSDL file. This is nil if the WSDL could not be fetched.
    #
    # service_info structure:
    #   { 
    #     "name"        => "...",
    #     "description" => "...",
    #     "namespace"   => "...",
    #     "endpoint"    => "...",
    #     "ports"       => 
    #       [
    #         {
    #           "name"     => "..."
    #           "protocol" => "..."
    #           "style"    => "style of the communication. Eg document"
    #           "location" => "uri to an endpoint of the service"
    #         }
    #       ]
    #     "operations"  => 
    #       [
    #         { 
    #           "name"             => "...", 
    #           "description"      => "...",
    #           "action"           => "...",
    #           "parent_port_type" => "port to which operation is bound",
    #           "operation_type"   => "...",
    #           "inputs"           => 
    #             [
    #               { 
    #                 "name"                       => "...",
    #                 "description"                => "...",
    #                 "computational_type"         => "...",
    #                 "computational_type_details" => { ... }
    #
    #               },
    #               { ... } 
    #             ]
    #           "outputs"          => 
    #             [
    #               { 
    #                 "name"                       => "...",
    #                 "description"                => "...",
    #                 "computational_type"         => "...",
    #                 "computational_type_details" => { ... }
    #               },
    #               { ... }
    #             ] 
    #         },
    #         { ... } 
    #       ] 
    #   }
    def self.parse(wsdl_url)
      Rails.logger.info('Using PHP WSDLUtils parser.')
      service_info, error_messages, wsdl_file_contents = BioCatalogue::WsdlUtils::ParserClient.parse(wsdl_url)
      # Forget about the legacy parser - it is even worse and wipes out all useful error messages from WSDLUtils
      #if service_info.blank?
      #  Util.warn "Trying the old parser - BioCatalogue::WsdlParser::Legacy.parse(...) - because the BioCatalogue::WsdlUtils::ParserClient.parse(...) failed"
      #  service_info, error_messages, wsdl_file_contents = BioCatalogue::WsdlParser::Legacy.parse(wsdl_url)
      #end
      return [service_info, error_messages, wsdl_file_contents]
    end

    def self.parse_via_tavernas_wsdl_generic(wsdl_url)
      Rails.logger.info("Using Taverna's wsdl-generic WSDL parser.")
      service_info, error_messages, wsdl_file_contents = {}, [], nil

      begin
        timeout(20.seconds) do
          wsdl_file_contents = open(wsdl_url.strip(), :proxy => HTTP_PROXY, "User-Agent" => HTTP_USER_AGENT).read
        end
      rescue Exception => ex
        error_message = "Error while downloading WSDL document from #{wsdl_url}. Exception: #{ex.class.name} - #{ex.message}."
        error_stacktrace = ex.backtrace.join("\n")
        Rails.logger.error(error_message)
        Rails.logger.error(error_stacktrace)
        error_messages << error_message + error_stacktrace
        service_info = nil
        wsdl_file_contents = nil
        return [service_info, error_messages, wsdl_file_contents]
      end

      begin
        taverna_wsdl_parser_class = Rjb::import('net.sf.taverna.wsdl.parser.WSDLParser')

        parsed_wsdl = taverna_wsdl_parser_class.new(wsdl_url)

        definition = parsed_wsdl.getDefinition()

        if definition == nil
          error_messages << "No <definitions> element found in the WSDL at #{wsdl_url}."
        else
          # We only care about the first service defined - if there is such
          service = definition.getServices().values().iterator().next()

          # Parser will only return SOAP operations, others, such as
          # HTTP operations are disregarded.
          operations = parsed_wsdl.getOperations()

          service_info = {}

          service_info['name'] = service.getQName().getLocalPart()

          service_info['description'] = parsed_wsdl.getServiceDocumentation()

          service_info['namespace'] = definition.getTargetNamespace()

          service_info['ports'] = []

          service_info['operations'] = []

          # Populate service ports
          port_itr = service.getPorts().values().iterator()
          while port_itr.hasNext()
            p = port_itr.next()

            # Get binding for this port
            binding = p.getBinding()

            # Disregard this port if it is NOT using SOAP binding, i.e. binding's protocol is not "http://schemas.xmlsoap.org/soap/http"
            next unless parsed_wsdl.isSOAPBinding(binding)

            port = {}
            port['name'] = p.getName()
            port['protocol'] = parsed_wsdl.getTransportForSOAPBinding(binding)
            port['style'] = parsed_wsdl.getStyle()
            port['location'] = parsed_wsdl.getSOAPAddressLocationForPort(p)

            service_info['ports'] << port
          end

          # Populate service operations - list all operations for all ports of this service with
          # all the details about the operations - inputs, outputs, computational types, order, etc.
          i = 0
          while i < operations.size() do
            op = operations.get(i)

            operation = {}
            operation['name'] = op.getName()
            operation['description'] = parsed_wsdl.getOperationDocumentation(op.getName())
            endpoint_locations = parsed_wsdl.getOperationEndpointLocations(op.getName())
            operation['action'] = endpoint_locations.isEmpty() ? '' : endpoint_locations.get(0)
            operation['operation_type'] = '' #?
            operation['parameter_order'] = parsed_wsdl.getParameterOrder(op)
            operation['parent_port_type'] = parsed_wsdl.getPortForOperation(op.getName()).getName() # the name of the port (not portType!) element that contains the binding that this operation belongs to
            operation['inputs'] = []
            operation['outputs'] = []

            # Build hashes for inputs and outputs of this operation
            inputs = parsed_wsdl.getOperationInputParameters(op.getName())
            j = 0
            while j < inputs.size() do
              input = inputs.get(j)
              inp = {}
              inp['name'] = input.getName()
              #inp['description'] = input.getDocumentation()
              inp['computational_type'] = input.getType()
              computational_type_details = build_message_type_details(input)
              if input._classname != 'net.sf.taverna.wsdl.parser.BaseTypeDescriptor'
                # Fix the name of the top element of complex and array types
                computational_type_details['name'] = input.getType()
              end
              inp['computational_type_details'] = computational_type_details
              operation['inputs'] << inp
              j += 1
            end

            outputs = parsed_wsdl.getOperationOutputParameters(op.getName())
            j = 0
            while j < outputs.size() do
              output = outputs.get(j)
              out = {}
              out['name'] = output.getName()
              #out['description'] = input.getDocumentation()
              out['computational_type'] = output.getType()
              computational_type_details = build_message_type_details(output)
              if output._classname != 'net.sf.taverna.wsdl.parser.BaseTypeDescriptor'
                # Fix the name of the top element of complex and array types
                computational_type_details['name'] = output.getType()
              end
              out['computational_type_details'] = computational_type_details

              operation['outputs'] << out
              j += 1
            end

            service_info['operations'] << operation
            i += 1
          end

          # Set the location of the first port as the default endpoint - this is not
          # used anyway by the look of things
          service_info["endpoint"] = get_default_endpoint(service_info["ports"])
        end
      rescue Exception => ex
        error_message = "Error while parsing WSDL document from #{wsdl_url}. Exception: #{ex.class.name} - #{ex.message}.\n"
        error_stacktrace = ex.backtrace.join("\n")
        Rails.logger.error(error_message)
        Rails.logger.error(error_stacktrace)
        service_info = nil
        wsdl_file_contents = nil
        error_messages << error_message + error_stacktrace
      end

      return [service_info, error_messages, wsdl_file_contents]
    end

    # Build message type elements from net.sf.taverna.wsdl.parser.TypeDescriptor
    # Each TypeDescriptor represents one input parameter for a SOAP operation and
    # can be simple, complex, or an array.
    #
    # We are also caching the types we have seen before for handling types that contain elements
    # that reference itself or another parent. Without the caching, this could lead to
    # infinite recursion.

    # It returns a recursive hash like:
    # {
    #   'name' => '...',
    #   'type' => [
    #               {'name' => '...',
    #                'type' => [...]
    #               },
    #               ...
    #             ]
    # }
    def self.build_message_type_details(type_descriptor, cached_types = {})
      return {} if type_descriptor.nil?

      message_type_details = {}
      message_type_details['name'] = type_descriptor.getName().nil? ? '' : type_descriptor.getName();

      ############################################################################
      # Remember that for RJB to work you have to set JAVA_HOME variable on linux.
      # On a Mac OS X, you need to set appropriate Java version using /System/Library/Frameworks/JavaVM.framework/Libraries symbolic link.
      type_descriptor_class = Rjb::import('net.sf.taverna.wsdl.parser.TypeDescriptor')

      if type_descriptor._classname == 'net.sf.taverna.wsdl.parser.BaseTypeDescriptor'
        message_type_details['type'] = type_descriptor.getType()
      else
        # Caching the type here for handling types that contain elements
        # that reference itself or another parent. Without the caching, this could lead to
        # infinite recursion.
        if type_descriptor_class.isCyclic(type_descriptor)
          if !cached_types["#{type_descriptor.getQname().toString()}"].nil?
            message_type_details['type'] = type_descriptor.getType
            return message_type_details
          end
          cached_types["#{type_descriptor.getQname().toString()}"] = type_descriptor.getQname().toString()
        end

        if type_descriptor._classname == 'net.sf.taverna.wsdl.parser.ComplexTypeDescriptor'
          elements = type_descriptor.getElements()
          parts = []
          if elements.size() > 1
            i = 0
            while i < elements.size() do
              parts << build_message_type_details(elements.get(i), cached_types)
              i += 1
            end
          elsif elements.size() == 1
            parts = [build_message_type_details(elements.get(0)), cached_types]
          end
          message_type_details['type'] = parts
        elsif type_descriptor._classname == 'net.sf.taverna.wsdl.parser.ArrayTypeDescriptor'
          type_descriptor.getElementType().setName(type_descriptor.getElementType().getType()) if type_descriptor.getElementType().getName().nil?
          message_type_details['type'] = [build_message_type_details(type_descriptor.getElementType(), cached_types)]
        end
      end
      return message_type_details
    end

    # Get location/URI of the first endpoint (port element)
    def self.get_default_endpoint(ports)
      endpoint = nil
      unless ports.empty?
        endpoint = ports[0]["location"]
      end
      return endpoint
    end


    # ==========
    # Below is the old WSDL parser used in the early days. 
    # This is still used as a fallback in cases where the WSDLUtils parser fails or is not available.
    # ==========
    module Legacy

      MOBY_STYLE_WSDL_KEYS = ['name', 'target_namespace', 'import'].freeze

      # This method takes a URL to a WSDL file and returns back the following array:
      # [ service_info, error_messages, wsdl_file_contents ]
      # 
      # where:
      # - service_info: the information about the service in a structured, hierarchical form (see below). This is an empty hash if breaking errors occurred.
      # - error_messages: collection (array) of error messages that may have been raised during parsing (these can include breaking or non-breaking errors).
      # - wsdl_file_contents: the contents of the actual WSDL file. This is nil if the WSDL could not be fetched.
      #
      # service_info structure:
      #   { 
      #     "name"         => "...",
      #     "description"  => "...",
      #     "endpoint"    => "...",
      #     "operations"   => 
      #         [
      #         { 
      #           "name"         => "...", 
      #           "description"  => "...",
      #           "inputs"       => 
      #               [
      #               { 
      #                 "name"                 => "...",
      #                 "description"          => "...",
      #                 "computational_type"   => "..."
      #               },
      #               { ... } 
      #               ]
      #           "outputs"      => 
      #               [
      #               { 
      #                 "name"                => "...",
      #                 "description"         => "...",
      #                 "computational_type"  => "..." 
      #               },
      #               { ... }
      #               ] 
      #         },
      #         { ... } 
      #         ] 
      #   }
      #
      # Known Issues:
      # This module uses the rails Hash.from_xml function to generate a hash of the wsdl document
      # from the xml file contents. It turns out that generated hash may be incomplete, notably that 
      # some message and/or operation details are left out. This causes those wsdls to fail the parsing 
      # hence the registration. The method 
      #          WsdlParser.check_for_xml_parse_errors
      # tries to identify this problem. 
      #
      def self.parse(wsdl_url="")
        service_info = {}
        error_messages = []
        wsdl_file_contents = nil
        wsdl_hash = nil

        begin
          timeout(20.seconds) do
            wsdl_hash, wsdl_file_contents = get_wsdl_hash_and_file_contents(wsdl_url)
          end
          if wsdl_hash.nil?
            error_messages << "The WSDL file could not be parsed. It may be invalid."
          end

        rescue Exception => ex
          error_messages << "There was a problem loading the WSDL file '#{wsdl_url}'. Exception message: #{ex.message}."
          Rails.logger.error("Exception occurred whilst loading WSDL '#{wsdl_url}'. Exception:")
          Rails.logger.error(ex.message)
          Rails.logger.error(ex.backtrace.join("\n"))
        end

        if error_messages.empty?
          begin
            service_info = get_service_info(wsdl_hash)
          rescue Exception => ex
            error_messages << "There was a problem parsing the WSDL file '#{wsdl_url}'. Exception message: #{ex.message}."
            Rails.logger.error("Exception occurred whilst parsing WSDL '#{wsdl_url}'. Exception:")
            Rails.logger.error(ex.message)
            Rails.logger.error(ex.backtrace.join("\n"))
          end
        end
        return [service_info, error_messages, wsdl_file_contents]
      end

      # This method takes a wsdl url and returns a hash of its contents
      # The structure of the wsdl_hash looks like
      # {
      #  "definitions" => {
      #                     "message"  => [...], # messages sent to/receive from service
      #                     "service"  => {}, # service attributes like name
      #                     "PortType" => [...], # contains operations defined by service
      #                     "types"    => [...], # types defined by service
      #                     "binding"  => [...], #operation and service bindings
      #                     "documentation" => "service documentation"
      #                    }
      # }
      #
      def self.get_wsdl_hash_and_file_contents(wsdl_url)
        wsdl_file_contents = open(wsdl_url.strip(), :proxy => HTTP_PROXY, "User-Agent" => HTTP_USER_AGENT).read
        wsdl_hash = Hash.better_from_xml(wsdl_file_contents, :preserve_attributes => true)
        if wsdl_hash['definitions'].keys == MOBY_STYLE_WSDL_KEYS
          wsdl_hash = moby_wsdl_adapter(wsdl_hash)
        end
        return [wsdl_hash, wsdl_file_contents]
      end

      protected

      def self.get_service_info(wsdl_hash)
        #wsdl_hash = check_for_xml_parse_errors(wsdl_hash)
        service_info = {}
        service_info["name"] = wsdl_hash["definitions"]["service"]["name"]
        service_info["description"] = wsdl_hash["definitions"]["documentation"] || wsdl_hash["definitions"]["service"]["documentation"] || wsdl_hash["definitions"]["service"]['port']["documentation"]
        service_info["endpoint"] = Addressable::URI.parse(get_service_endpoint(wsdl_hash)).normalize.to_s

        operations_ = map_messages_and_operations(wsdl_hash)
        service_info["operations"] = format_operations(operations_)
        service_info
      end

      def self.map_messages_and_operations(wsdl_hash)
        messages = wsdl_hash["definitions"]["message"]
        port_type = wsdl_hash["definitions"]["port_type"]
        operations = []
        if port_type.class.to_s =="Array"
          port_type.each { |a_pt|

            pt_op = a_pt["operation"]
            if pt_op.class.to_s =="Array"
              pt_op.each { |op| op["parent_port_type"]=a_pt["name"] }
              operations.concat(pt_op)
            else
              pt_op["parent_port_type"] =a_pt["name"]
              operations << pt_op
            end

          }
        else
          operations = wsdl_hash["definitions"]["port_type"]["operation"]
          unless operations.class.to_s == "Array"
            operations =[operations]
          end
          operations.each { |op| op["parent_port_type"] = port_type["name"] }
        end

        unless  wsdl_hash["definitions"]["types"] == nil
          if wsdl_hash["definitions"]["types"].class.to_s =="Array"
            wsdl_hash["definitions"]["types"].each { |type|
              unless type["schema"] == nil

                if type["schema"].class.to_s == "Array"
                  elements =[]
                  type["schema"].each { |schema|
                    unless schema["element"]== nil
                      if schema["element"].class.to_s =="Array"
                        elements.concat(schema["element"])
                      else
                        elements << schema["element"]
                      end
                    end
                  }
                else
                  elements = type["schema"]["element"] || nil
                end

              end
            }
          else

            if wsdl_hash["definitions"]["types"]["schema"].class.to_s == "Array"
              elements =[]
              wsdl_hash["definitions"]["types"]["schema"].each { |schema|
                unless schema["element"]== nil
                  if schema["element"].class.to_s =="Array"
                    elements.concat(schema["element"])
                  else
                    elements << schema["element"]
                  end
                end
              }

            elsif wsdl_hash["definitions"]["types"]["schema"]["element"]

              elements = wsdl_hash["definitions"]["types"]["schema"]["element"] || nil

            else
              # possibly wsdl_hash["definitions"]["types"].class.to_s == "Hash"

              puts " Warning : this is probably a complex type without a schema definition. The complex types may not be expanded completely "
            end
          end
        end

        unless operations.class.to_s == "Array"
          operations =[operations]
        end
        operations.each do |operation|

          operation["description"] = operation["documentation"]
          operation.delete("documentation")

          #input/output msg for this operation
          in_msg = operation["input"]["message"]
          out_msg = operation["output"]["message"]

          #get message name without namespace prefix
          if in_msg.split(":").length > 1
            in_msg = in_msg.split(":")[1]
          end
          #get message name without namespace prefix
          if out_msg.split(":").length > 1
            out_msg = out_msg.split(":")[1]
          end

          messages.each { |message|
            if message["name"] == in_msg
              operation["input"]["message"]= expand_message_element(message, elements)
            end

            if message["name"] == out_msg
              operation["output"]["message"]= expand_message_element(message, elements)
            end
          }
        end

        operations
      end

      def self.expand_message_element(message, elements)
        if message["part"].class.to_s == "Hash"
          if message["part"].has_key?("element")
            elm = message["part"]["element"]
            if elm.include?(':')
              if elm.split(":").length > 1
                elm = elm.split(":")[1]
              end
            end
            if elements == nil || []
              message["part"]["element"] = {"name" => elm}
            else
              elements.each { |element|
                if element["name"] == elm
                  message["part"]["element"] = element
                end
              }
            end
          end
        end
        message
      end

      def self.format_operations(operations)
        f_operations = []
        operations.each { |operation|
          operation.each { |k, v| operation[ActiveSupport::Inflector.underscore(k)]=v }

          in_parts = operation["input"]["message"]["part"]
          out_parts = operation["output"]["message"]["part"]

          if in_parts.class.to_s =="Hash"
            operation["inputs"]= [in_parts]
            unless in_parts["element"]== nil
              if in_parts["element"]["complex_type"]== nil
                operation["inputs"] = [in_parts["element"]]
              else
                elm = in_parts["element"]["complex_type"]["sequence"]["element"]
                operation["inputs"]= elm

                unless elm.class.to_s =="Array"
                  operation["inputs"] =[elm]
                end
                #operation["inputs"]= in_parts["element"]["complexType"]["sequence"]["element"]
              end
            end
          else
            operation["inputs"] = in_parts
          end

          if out_parts.class.to_s =="Hash"
            operation["outputs"]= [out_parts]
            unless out_parts["element"]== nil
              if out_parts["element"]["complex_type"]==nil
                operation["outputs"] = [out_parts["element"]]
              else
                elm = out_parts["element"]["complex_type"]["sequence"]["element"]
                operation["outputs"]= elm

                unless elm.class.to_s =="Array"
                  operation["outputs"] =[elm]
                end
              end
            end
          else
            operation["outputs"]= out_parts
          end

          operation.delete("fault") if operation.has_key?("fault") # handle this post pilot
          operation.delete("input")
          operation.delete("output")
          format_input_output(operation["inputs"])
          format_input_output(operation["outputs"])

          operation["inputs"] = [] if operation["inputs"].nil?
          operation["outputs"] = [] if operation["outputs"].nil?

        }

        f_operations = camel_case_to_underscore(operations)
        return f_operations
      end

      def self.camel_case_to_underscore(list)
        new_list =[]
        list.each { |item|
          h = {}
          item.each { |k, v| h[ActiveSupport::Inflector.underscore(k)]=v }
          new_list << h
        }
        return new_list
      end


      def self.format_input_output(list)
        unless list== nil
          list.each { |item|
            cleanup_input_output_params(item)
          }
        end
      end

      def self.cleanup_input_output_params(item)
        if item.class.to_s != "Hash"
          return {}
        end
        db_fields = ["name", "description", "computational_type",
                     "min_occurs", "max_occurs"]

        if item.has_key?("type")
          item["computational_type"] = item["type"]
          item.delete("type")
        end
        if item.has_key?("max_occurs")
          item["max_occurs"] = item["max_occurs"]
          item.delete("max_occurs")
        end
        if item.has_key?("min_occurs")
          item["min_occurs"] = item["min_occurs"]
          item.delete("min_occurs")
        end
        #if item.has_key?("complexType")
        #  item.delete("complexType")
        #end

        item.keys.each { |key|
          if !db_fields.include?(key)
            item.delete(key)
            #logger.warning("#{key} => #{item[key]} was removed")
          end
        }
        return item
      end

      def self.get_service_endpoint(wsdl_hash)
        ports = wsdl_hash["definitions"]["service"]["port"]
        endpoint = nil
        # assumes only one port
        if ports.class.to_s =="Hash"
          endpoint = ports["address"]["location"]
        end
        # assumes only multiple ports
        if ports.class.to_s =="Array"
          endpoint = ports[0]["address"]["location"] #get endpoint from first port
        end
        endpoint
      end

      #
      # some messages are not parsed properly. This means that the operations
      # which use those messages are not correctly parsed as well.
      # This method scans messages and tries to rectify the parsing problems

      def self.scan_messages_for_parse_errors(messages)
        checked_messages = []
        messages.each do |msg|
          name = msg["name"]
          part = msg["part"]
          if part.class.to_s != "Hash"
            if part.class.to_s == "String"
              puts "There seems to be a problem with the parsing of this message"

              #part = {"name" => "parameters", "element" =>name }
              part = {"name" => name}
              puts "New parts after problem"
              pp part
              msg["part"] = part
            end
          end
          checked_messages << msg
        end
        checked_messages
      end


      # some operations are not parsed properly. This means that it may not be exactly
      # clear what messages they use
      # This method scans operations and tries to rectify the parsing problems

      def self.scan_operations_for_parse_error(operations, message_names)
        checked_operations =[]
        if operations.class.to_s == "Hash"
          operations = [operations]
        end
        operations = operations.compact
        operations.each do |op|
          name = op["name"]
          input = op["input"]
          output = op["output"]

          if input.class.to_s != "Hash"
            if input.class.to_s == "String"
              puts "Seem there is a parsing error with this input"
              if message_names.include?(name+"Request")
                op["input"] ={"message" => name+"Request"}
              elsif message_names.include?(name)
                op["input"] ={"message" => name}
              end
            end
          end
          if output.class.to_s != "Hash"
            if output.class.to_s == "String"
              puts "Seems there is a parsing error with this output"
              if message_names.include?(name+"Response")
                op["output"] ={"message" => name+"Response"}
              elsif message_names.include?(name)
                op["output"] ={"message" => name}
              end
            end
          end
          checked_operations << op
        end
        checked_operations
      end

      def self.check_for_xml_parse_errors(wh)
        message_names = []
        wh["definitions"]["message"].each { |m| message_names << m["name"] unless m["name"].nil? }
        wh["definitions"]["message"] = scan_messages_for_parse_errors(wh["definitions"]["message"])
        if wh["definitions"]["port_type"].class.to_s =="Array"
          wh["definitions"]["port_type"].each do |pt|
            pt["operation"] = scan_operations_for_parse_error(pt["operation"], message_names)
          end
        else
          wh["definitions"]["port_type"]["operation"] = scan_operations_for_parse_error(wh["definitions"]["port_type"]["operation"], message_names)
        end

        wh
      end

      def self.get_service_name(wsdl_hash)
        name =""
        if wsdl_hash["definitions"]["service"].class.to_s == "Array"
          puts "multiple services in this wsdl..."
          wsdl_hash["definitions"]["service"].each do |service|
            name += " #{service["name"]}"
          end
        else
          name = wsdl_hash["definitions"]["service"]["name"]
        end
        return name
      end


      def self.moby_wsdl_adapter(moby_style_wsdl_hash)
        wsdl_hash = {'definitions' => {'service' => nil,
                                       'message' => nil,
                                       'types' => nil,
                                       'port_type' => nil
        }
        }
        messages = []
        types = []
        porttype = []
        service = nil

        import = moby_style_wsdl_hash['definitions']['import']
        import.each do |item|
          unless item.class.to_s !='Hash'
            if item.keys.include?('schema')
              types << item
            elsif item.keys.include?('part')
              messages << item
            elsif item.keys.include?('port')
              service = item
            else
              if item.keys.include?('operation')
                porttype << item if item['name'] =~/PortType/
              end
            end
          end
        end
        wsdl_hash['definitions']['service'] = service
        wsdl_hash['definitions']['message'] = messages
        wsdl_hash['definitions']['types'] = types
        wsdl_hash['definitions']['port_type'] = porttype

        return wsdl_hash
      end

      def self.test(num=0)
        wsdls= [
            "http://www.inab.org/cgi-bin/getMOBYWSDL/INB-dev/mmb.pcb.ub.es/solvateStructureWithLigandsFromPDBText",
            "http://www.inab.org/cgi-bin/getMOBYWSDL/INB/inb.bsc.es/runNCBIBlastn",
            "http://www.inab.org/cgi-bin/getMOBYWSDL/INB/inb.bsc.es/runNCBIBlastn",
            "http://edoc3.bibliothek.uni-halle.de:8080/axis/vascoda.wsdl",
            "http://www.biomart.org/biomart/martwsdl",
            "http://www.ebi.ac.uk/Tools/webservices/wsdl/WSWUBlast.wsdl",
            "http://www.ebi.ac.uk/ebisearch/service.ebi?wsdl",
            "http://www.ebi.ac.uk/Tools/webservices/wsdl/WSBlastpgp.wsdl",
            "http://www.cbs.dtu.dk/ws/GenomeAtlas/GenomeAtlas_3_0_ws0.wsdl",
            "http://omabrowser.org/omabrowser.wsdl",
            "http://www.cbs.dtu.dk/ws/SignalP/SignalP_3_1_ws0.wsdl",
            "http://biomoby.org/services/wsdl/biomoby.renci.org/Water",
            "http://wsembnet.vital-it.ch/soaplab2/services/embnet.blastp?wsdl",
            "http://www.ebi.ac.uk/intact/binary-search-ws/binarysearch?wsdl",
            "http://www.ebi.ac.uk/Tools/webservices/wsdl/WSCensor.wsdl",
            "http://www.ebi.ac.uk/ebisearch/service.ebi?wsdl",
            "http://www.webservicex.com/globalweather.asmx?WSDL",
            "http://ws.chss.homeport.info/ChssAdvWS.asmx?WSDL",
            "http://gbio-pbil.ibcp.fr/ws/ClustalwWS.wsdl",
            "http://togows.dbcls.jp/soap/wsdl/ddbj_blastdemo.wsdl",
            "http://www.ebi.ac.uk/Tools/webservices/wsdl/WSFasta.wsdl",
            "http://biomoby.org/services/wsdl/biomoby.renci.org/Blast",
            "http://togows.dbcls.jp/soap/wsdl/ddbj_sps.wsdl"
        ]
        wh = get_wsdl_hash_and_file_contents(wsdls[num])[0]
        pp wh
        return wh
      end

    end
  end
end
