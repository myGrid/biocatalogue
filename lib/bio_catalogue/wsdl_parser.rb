# BioCatalogue: lib/bio_catalogue/wsdl_parser.rb
#
# Copyright (c) 2008, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

require 'open-uri'
require 'active_support/inflector'
require 'pp'
require 'addressable/uri'

module BioCatalogue
  module WsdlParser
    
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
    #     :name         => "service_name",
    #     :description  => "service_description",
    #     :operations   => 
    #         [
    #         { 
    #           :name         => "op_name", 
    #           :description  => "op_description",
    #           :inputs       => 
    #               [
    #               { 
    #                 :name                 => "input_name",
    #                 :computational_type   => "computational_type" 
    #               },
    #               { ... } 
    #               ]
    #           :outputs      => 
    #               [
    #               { 
    #                 :name                => "output_name",
    #                 :computational_type  => "computational_type" 
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
    #TODO: replace this wsdl parser by an elaborate wsdl handling library
    
    
   
    def WsdlParser.parse(wsdl_url="")
      
      service_info       = { }
      error_messages     = [ ]
      wsdl_file_contents = nil
      wsdl_hash          = nil
      
      begin
        wsdl_hash, wsdl_file_contents = get_wsdl_hash_and_file_contents(wsdl_url)

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
          service_info  = get_service_info(wsdl_hash)
        rescue Exception => ex
          error_messages << "There was a problem parsing the WSDL file '#{wsdl_url}'. Exception message: #{ex.message}."
          Rails.logger.error("Exception occurred whilst parsing WSDL '#{wsdl_url}'. Exception:")
          Rails.logger.error(ex.message)
          Rails.logger.error(ex.backtrace.join("\n"))
        end
      end
      return [ service_info, error_messages, wsdl_file_contents ]
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
    def WsdlParser.get_wsdl_hash_and_file_contents(wsdl_url)
      wsdl_file_contents  = open(wsdl_url.strip(), :proxy => HTTP_PROXY).read
      wsdl_hash = Hash.from_xml(wsdl_file_contents)
      return [wsdl_hash, wsdl_file_contents]
    end

    
    protected    
    def WsdlParser.get_service_info(wsdl_hash)
      wsdl_hash = check_for_xml_parse_errors(wsdl_hash)
      service_info = {}
      service_info["name"]        = wsdl_hash["definitions"]["service"]["name"]
      service_info["description"] = wsdl_hash["definitions"]["documentation"] || wsdl_hash["definitions"]["service"]["documentation"] || wsdl_hash["definitions"]["service"]['port']["documentation"]
      service_info["end_point"]   = Addressable::URI.parse(get_service_end_point(wsdl_hash)).normalize.to_s
      
      operations_ = map_messages_and_operations(wsdl_hash)
      service_info["operations"] = format_operations(operations_) 
      service_info
    end
    
    def WsdlParser.map_messages_and_operations(wsdl_hash)
      messages   = wsdl_hash["definitions"]["message"]
      port_type  = wsdl_hash["definitions"]["port_type"]
      operations = []
      if port_type.class.to_s =="Array"
        port_type.each{ |a_pt|
      
          pt_op = a_pt["operation"] 
          if pt_op.class.to_s =="Array"
            pt_op.each{|op| op["parent_port_type"]=a_pt["name"]}
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
        operations.each{ |op| op["parent_port_type"] = port_type["name"]}
      end
      
      unless  wsdl_hash["definitions"]["types"] == nil
        if wsdl_hash["definitions"]["types"].class.to_s =="Array"
          wsdl_hash["definitions"]["types"].each{ |type|
           unless type["schema"] == nil
             
             if type["schema"].class.to_s == "Array"
                elements =[]
                type["schema"].each{ |schema|
                  unless schema["element"]== nil
                    if schema["element"].class.to_s =="Array"
                      elements.concat(schema["element"])
                    else
                      elements << schema["element"]
                    end
                  end
                }
            else
                elements   = type["schema"]["element"] || nil  
            end
             
           end
          }
        else
          
          if wsdl_hash["definitions"]["types"]["schema"].class.to_s == "Array"
            elements =[]
            wsdl_hash["definitions"]["types"]["schema"].each{ |schema|
              unless schema["element"]== nil
                if schema["element"].class.to_s =="Array"
                  elements.concat(schema["element"])
                else
                  elements << schema["element"]
                end
              end
              }
           
         elsif wsdl_hash["definitions"]["types"]["schema"]["element"]
           
              elements   = wsdl_hash["definitions"]["types"]["schema"]["element"] || nil  
              
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
        in_msg  = operation["input"]["message"]
        out_msg = operation["output"]["message"]
        
        #get message name without namespace prefix
        if in_msg.split(":").length > 1
          in_msg = in_msg.split(":")[1]
        end
        #get message name without namespace prefix
        if out_msg.split(":").length > 1
          out_msg = out_msg.split(":")[1]
        end
        
        messages.each{ |message|
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
    
    def WsdlParser.expand_message_element(message, elements)
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
          elements.each{ |element|
            if element["name"] == elm
              message["part"]["element"] = element
            end
            }
          end
        end
      end
      message
    end
    
    def WsdlParser.format_operations(operations)
      f_operations = []
      operations.each{ |operation| 
        operation.each{|k, v| operation[ActiveSupport::Inflector.underscore(k)]=v}
        
        in_parts  = operation["input"]["message"]["part"]
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
         
         operation["inputs"] = [ ] if operation["inputs"].nil?
         operation["outputs"] = [ ] if operation["outputs"].nil?
       
       }
       
      f_operations = camel_case_to_underscore(operations)
      return f_operations
    end
    
    def WsdlParser.camel_case_to_underscore(list)
      new_list =[]
      list.each{ |item|
      h = {}
      item.each{|k, v| h[ActiveSupport::Inflector.underscore(k)]=v}
      new_list << h
      }
      return new_list
    end
    
    
    #def WsdlParser.type_to_computational_type(list)
    def WsdlParser.format_input_output(list)
      unless list== nil
        list.each {|item|
          cleanup_input_output_params(item) 
        }
      end
    end
    
    def WsdlParser.cleanup_input_output_params(item)
      if item.class.to_s != "Hash"
        return {}
      end
      db_fields = ["name","description","computational_type",
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
      
      item.keys.each{ |key| 
        if !db_fields.include?(key)
          item.delete(key)
          #logger.warning("#{key} => #{item[key]} was removed")
        end
        }
      return item
    end
    
    def WsdlParser.get_service_end_point(wsdl_hash)
      ports = wsdl_hash["definitions"]["service"]["port"]
      end_point = nil
      # assumes only one port
      if ports.class.to_s =="Hash"
        end_point = ports["address"]["location"]
      end
      # assumes only multiple ports
      if ports.class.to_s =="Array"
        end_point = ports[0]["address"]["location"] #get endpoint from first port
      end
      end_point
    end
    
    #
    # some messages are not parsed properly. This means that the operations
    # which use those messages are not correctly parsed as well.
    # This method scans messages and tries to rectify the parsing problems
    
    def WsdlParser.scan_messages_for_parse_errors(messages)
      checked_messages = []
      messages.each do |msg|
        name = msg["name"]
        part = msg["part"]
        if part.class.to_s != "Hash"
          if part.class.to_s == "String"
            puts "There seems to be a problem with the parsing of this message"
            
            #part = {"name" => "parameters", "element" =>name }
            part = {"name"  => name }
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
        
      def WsdlParser.scan_operations_for_parse_error(operations, message_names)
        checked_operations =[]
        if operations.class.to_s == "Hash"
          operations = [operations]
        end
        operations.each do |op|
          name = op["name"]
          input  = op["input"]
          output = op["output"]
          
          if input.class.to_s != "Hash"
            if input.class.to_s == "String"
              puts "Seem there is a parsing error with this input"
              if message_names.include?(name+"Request")
                op["input"] ={"message"=>name+"Request"}
              elsif message_names.include?(name)
                op["input"] ={"message"=>name}
              end
            end
          end
          if output.class.to_s != "Hash"
            if output.class.to_s == "String"
              puts "Seems there is a parsing error with this output"
              if message_names.include?(name+"Response")
                op["output"] ={"message"=>name+"Response"}
              elsif message_names.include?(name)
                op["output"] ={"message"=>name}
              end
            end
          end
          checked_operations << op
        end
        checked_operations
      end
      
      def WsdlParser.check_for_xml_parse_errors(wh)
        message_names = [] 
        wh["definitions"]["message"].each{ |m| message_names <<  m["name"] unless m["name"].nil?}
        wh["definitions"]["message"] = scan_messages_for_parse_errors(wh["definitions"]["message"])
        if wh["definitions"]["port_type"].class.to_s =="Array"
          wh["definitions"]["port_type"].each  do |pt|
            pt["operation"] = scan_operations_for_parse_error(pt["operation"], message_names)
          end
        else
          wh["definitions"]["port_type"]["operation"] = scan_operations_for_parse_error(wh["definitions"]["port_type"]["operation"], message_names)
        end
        
        wh
      end
      
      def WsdlParser.get_service_name(wsdl_hash)
        name =""
        if wsdl_hash["definitions"]["service"].class.to_s == "Array"
          puts "multiple services in this wsdl..."
          wsdl_hash["definitions"]["service"].each do |service|
            name += " #{service["name"]}"
          end
        else
          name  = wsdl_hash["definitions"]["service"]["name"]
        end
        return name
      end
    
    def WsdlParser.test(num=0)
      wsdls= [
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
