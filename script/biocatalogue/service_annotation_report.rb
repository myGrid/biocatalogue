#!/usr/bin/env ruby

# Reports on the statistics of service annotations.
#
# Currently this just tells you: 
# A. How many SOAP Services that have a description.
# B. How many SOAP Services that have a description AND a documentation URL.
# C. How many SOAP Services that have a description AND all operations have a description.
# D. How many SOAP Services that have a description AND all operations have a description and ALL inputs/outputs have a description.
# E. How many SOAP Services that have a description AND all operations have a description and ALL inputs/outputs have a description AND example data.

env = "production"

unless ARGV[0].nil? or ARGV[0] == ''
  env = ARGV[0]
end

RAILS_ENV = env

# Load up the Rails app
require File.join(File.dirname(__FILE__), '..', '..', 'config', 'environment')

soap_services = SoapService.all

stats = { }
stats["soap_services_count"] = soap_services.length
stats["soap_services_A"] = 0
stats["soap_services_B"] = 0
stats["soap_services_C"] = 0
stats["soap_services_D"] = 0
stats["soap_services_E"] = 0

stats["soap_services_E_service_ids"] = [ ] 


def field_or_annotation_has_value?(obj, field, annotation_attribute=field.to_s)
  return (!obj.send(field).blank? || !obj.annotations_with_attribute(annotation_attribute).blank?)
end



soap_services.each do |soap_service|
  
  has_description = true
  has_doc_url = true
  all_ops_have_descriptions = true
  all_inputs_have_descriptions = true
  all_inputs_have_descriptions_and_data = true
  all_outputs_have_descriptions = true
  all_outputs_have_descriptions_and_data = true
  
  has_description = has_description && field_or_annotation_has_value?(soap_service, :description)
  
  has_doc_url = has_doc_url && field_or_annotation_has_value?(soap_service, :documentation_url)
  
  soap_service.soap_operations.each do |soap_operation|
    all_ops_have_descriptions = all_ops_have_descriptions && field_or_annotation_has_value?(soap_operation, :description)
    
    soap_operation.soap_inputs.each do |soap_input|
      all_inputs_have_descriptions = all_inputs_have_descriptions && field_or_annotation_has_value?(soap_input, :description)
      all_inputs_have_descriptions_and_data = all_inputs_have_descriptions_and_data && 
                                              field_or_annotation_has_value?(soap_input, :description) &&
                                              !soap_input.annotations_with_attribute("example_data").blank?
    end
    
    soap_operation.soap_outputs.each do |soap_output|
      all_outputs_have_descriptions = all_outputs_have_descriptions && field_or_annotation_has_value?(soap_output, :description)
      all_outputs_have_descriptions_and_data = all_outputs_have_descriptions_and_data && 
                                              field_or_annotation_has_value?(soap_output, :description) &&
                                              !soap_output.annotations_with_attribute("example_data").blank?
    end
  end
  
  puts ""
  puts "> SOAP Service ID: #{soap_service.id}, name: #{soap_service.name}:"
  puts "\t Has description? #{has_description}"
  puts "\t Has documentation URL? #{has_doc_url}"
  puts "\t No. of SOAP operations: #{soap_service.soap_operations.count}"
  puts "\t ALL operations have descriptions? #{all_ops_have_descriptions}"
  puts "\t ALL inputs have descriptions? #{all_inputs_have_descriptions}"
  puts "\t ALL inputs have descriptions AND example data? #{all_inputs_have_descriptions_and_data}"
  puts "\t ALL outputs have descriptions? #{all_outputs_have_descriptions}"
  puts "\t ALL outputs have descriptions AND example data? #{all_outputs_have_descriptions_and_data}"
  puts ""
  
  stats["soap_services_A"] += 1 if has_description
  stats["soap_services_B"] += 1 if has_description && has_doc_url
  stats["soap_services_C"] += 1 if has_description && all_ops_have_descriptions
  stats["soap_services_D"] += 1 if has_description && all_ops_have_descriptions && all_inputs_have_descriptions && all_outputs_have_descriptions
  
  if has_description && all_ops_have_descriptions && all_inputs_have_descriptions_and_data && all_outputs_have_descriptions_and_data
    stats["soap_services_E"] += 1
    stats["soap_services_E_service_ids"] << soap_service.service.id
  end
end


def report_stats(stats)
  puts ""
  puts "SUMMARY:"
  puts "========"
  puts ""
  
  puts "Total SOAP Services: #{stats["soap_services_count"]}"
  
  puts "A. How many SOAP Services have a description? #{stats["soap_services_A"]}"
  puts "B. How many SOAP Services have a description AND a documentation URL? #{stats["soap_services_B"]}"
  puts "C. How many SOAP Services have a description AND all operations have a description? #{stats["soap_services_C"]}"
  puts "D. How many SOAP Services have a description AND all operations have a description and ALL inputs/outputs have a description? #{stats["soap_services_D"]}"
  puts "E. How many SOAP Services have a description AND all operations have a description and ALL inputs/outputs have a description AND example data? #{stats["soap_services_E"]}"
  
  puts "Service IDs for E - #{stats["soap_services_E_service_ids"].to_sentence}"
end


report_stats(stats)



