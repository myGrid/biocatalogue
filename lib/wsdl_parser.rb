# BioCatalogue: app/lib/wsdl_parser.rb
#
# Copyright (c) 2008, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

require 'open-uri'
require 'active_support/inflector'
require 'pp'

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
        error_messages << "There was a problem loading the WSDL file - #{ex.message}."
      end
      
      if error_messages.empty?
        service_info  = get_service_info(wsdl_hash)
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
      service_info = {}
      service_info["name"]        = wsdl_hash["definitions"]["service"]["name"]
      service_info["description"] = wsdl_hash["definitions"]["documentation"] || wsdl_hash["definitions"]["service"]["documentation"]
      service_info["end_point"]   = Addressable::URI.parse(get_service_end_point(wsdl_hash)).normalize.to_s
      
      operations_ = map_messages_and_operations(wsdl_hash)
      service_info["operations"] = format_operations(operations_) 
      service_info
    end
    
    def WsdlParser.map_messages_and_operations(wsdl_hash)
      messages   = wsdl_hash["definitions"]["message"]
      port_type  = wsdl_hash["definitions"]["portType"]
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
        operations = wsdl_hash["definitions"]["portType"]["operation"]
        unless operations.class.to_s == "Array"
          operations =[operations]
        end
        operations.each{ |op| op["parent_port_type"] = port_type["name"]}
      end
      
      unless  wsdl_hash["definitions"]["types"] == nil
        unless wsdl_hash["definitions"]["types"]["schema"] == nil
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
          else
            elements   = wsdl_hash["definitions"]["types"]["schema"]["element"] || nil  
          end
        end
      end
      unless operations.class.to_s == "Array"
        operations =[operations]
      end
      pp operations
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
          if elm.split(":").length > 1
            elm = elm.split(":")[1]
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
             if in_parts["element"]["complexType"]== nil
                operation["inputs"] = [in_parts["element"]]
             else
               elm = in_parts["element"]["complexType"]["sequence"]["element"]
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
               if out_parts["element"]["complexType"]==nil
                  operation["outputs"] = [out_parts["element"]]
               else
                  elm = out_parts["element"]["complexType"]["sequence"]["element"]
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
      db_fields = ["name","description","computational_type",
                    "min_occurs", "max_occurs"]
                    
      if item.has_key?("type")
        item["computational_type"] = item["type"]
        item.delete("type")
      end                         
      if item.has_key?("maxOccurs")
        item["max_occurs"] = item["maxOccurs"]
        item.delete("maxOccurs")
      end
      if item.has_key?("minOccurs")
        item["min_occurs"] = item["minOccurs"]
        item.delete("minOccurs")
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
    
    def WsdlParser.test(num=0)
      wsdls= [
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
