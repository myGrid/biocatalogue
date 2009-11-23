#!/usr/bin/env ruby

# BioCatalogue: script/biocatalogue/import_annotations_io_examples_nov09.rb
#
# TODO: appropriate copyright statement
#
# Authors: Jerzy Orlowski and Jiten Bhagat
#
# Module for searching the input and output ports based on their example data
# by matching the query data with a set of regular expressions 



env = "production"

unless ARGV[0].nil? or ARGV[0] == ''
  env = ARGV[0]
end

RAILS_ENV = env

# Load up the Rails app
require File.join(File.dirname(__FILE__), '..', '..', 'config', 'environment')
IMPORT_ANNOTATION_FILE_PATH=File.join(RAILS_ROOT,'data','annotations_io_examples_nov09.xml')
DEFAULT_LOGIN="jerzyo"

#imports annotatation from XML file
#example file in 
#example of SQL query that generates the file
#    SELECT 
#  annotations.value AS annotation, 
#  annotatable_type AS type,
#  soap_inputs.name AS port_name,
#  soap_operations.name AS operation,
#  soap_services.name as service,
#  wsdl_location
#  FROM 
#    annotations, annotation_attributes, soap_inputs, soap_operations, soap_services
#  WHERE
#    annotations.attribute_id=annotation_attributes.id
#    AND annotation_attributes.name="Example"
#    AND annotations.annotatable_type="SoapInput"
#    AND soap_inputs.id=annotations.annotatable_id
#    AND soap_operations.id=soap_inputs.soap_operation_id
#    AND soap_services.id=soap_operations.soap_service_id
#UNION 
#SELECT 
#  annotations.value AS annotation, 
#  annotatable_type AS type,
#  soap_outputs.name AS port_name,
#  soap_operations.name AS operation,
#  soap_services.name as service,
#  wsdl_location
#  FROM 
#    annotations, annotation_attributes, soap_outputs, soap_operations, soap_services
#  WHERE
#    annotations.attribute_id=annotation_attributes.id
#    AND annotation_attributes.name="Example"
#    AND annotations.annotatable_type="SoapOutput"
#    AND soap_outputs.id=annotations.annotatable_id
#    AND soap_operations.id=soap_outputs.soap_operation_id
#    AND soap_services.id=soap_operations.soap_service_id  
def self.import_annotations(user_display_name,annotations_file_path=IMPORT_ANNOTATION_FILE_PATH)
  users=User.find(:all,
    :conditions => ["display_name = ?", user_display_name])
    if users.length==0
      raise 'No user fount'
    elsif users.length>1
      raise 'User ambiguous '
    else
      user=users[0]
      missing_port=0
      ambiguous_ports=0
      created_annotations=0
      existing_annotations=0
      annotations=[]
      parser = XML::Parser.file(annotations_file_path)
      doc = parser.parse
      node=doc.root
      doc.root.each_element do |annotation|
        annotation_value=annotation.find_first("annotation").inner_xml
        type=annotation.find_first("type").inner_xml
        port_name=annotation.find_first("port_name").inner_xml
        operation_name=annotation.find_first("operation").inner_xml
        service_name=annotation.find_first("service").inner_xml
        wsdl_location=annotation.find_first("wsdl_location").inner_xml
        if type=="SoapInput"
          sql= "SELECT soap_inputs.id 
            FROM soap_inputs, soap_operations,soap_services
            WHERE soap_inputs.soap_operation_id=soap_operations.id
              AND soap_operations.soap_service_id=soap_services.id
              AND soap_inputs.name='#{port_name}'
              AND soap_operations.name='#{operation_name}' 
              AND soap_services.name='#{service_name}' 
              AND soap_services.wsdl_location='#{wsdl_location}';"
              
          ports=ActiveRecord::Base.connection.select_all(sql)
          if ports.length==0
            missing_ports+=1
          elsif ports.length>1
            ambiguous_ports+=1
          else
            port=SoapInput.find(:first,:conditions=>["id=?",ports[0].values[0]])
            annotation_value2=CGI.unescapeHTML(annotation_value)
            new_annotations=port.create_annotations({"Example"=>[annotation_value2]},user)
            if new_annotations.length==1
              created_annotations+=1
            elsif new_annotations.length==0
              existing_annotations+=1
            end
          end
          
        elsif type=="SoapOutput"
          sql= "SELECT soap_outputs.id 
            FROM soap_outputs, soap_operations,soap_services
            WHERE soap_outputs.soap_operation_id=soap_operations.id
              AND soap_operations.soap_service_id=soap_services.id
              AND soap_outputs.name='#{port_name}'
              AND soap_operations.name='#{operation_name}' 
              AND soap_services.name='#{service_name}' 
              AND soap_services.wsdl_location='#{wsdl_location}';"
              
          ports=ActiveRecord::Base.connection.select_all(sql)
          if ports.length==0
            missing_ports+=1
          elsif ports.length>1
            ambiguous_ports+=1
          else
            port=SoapOutput.find(:first,:conditions=>["id=?",ports[0].values[0]])
            annotation_value2=CGI.unescapeHTML(annotation_value)
            new_annotations=port.create_annotations({"Example"=>[annotation_value2]},user)
            if new_annotations.length==1
              created_annotations+=1
            elsif new_annotations.length==0
              existing_annotations+=1
            end
          end
        end
      end
      puts "missing_port=#{missing_port}"
      puts "ambiguous_ports=#{ambiguous_ports}"
      puts "created_annotations=#{created_annotations}"
      puts "existing_annotations=#{existing_annotations}"
    end 
end

import_annotations(DEFAULT_LOGIN)