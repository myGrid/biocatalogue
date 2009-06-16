#!/usr/bin/env ruby

# This script ensures that entries for the initial versions of annotation objects
# are in the annotation_versions table (as required by the annotations versioning mechanism).
#
# Note: only creates annotation_version entries for those annotation objects are on version 1.

env = "development"

unless ARGV[0].nil? or ARGV[0] == ''
  env = ARGV[0]
end

RAILS_ENV = env

# Load up the Rails app
require File.join(File.dirname(__FILE__), '..', '..', 'config', 'environment')

Annotation::Version.record_timestamps = false

count = 0

Annotation.find(:all).each do |ann|
  if (ann.versions.length == 0) and (ann.version == 1)
    av = Annotation::Version.new
    
    av.annotation_id =    ann.id
    av.version =          1
    av.source_type =      ann.source_type
    av.source_id =        ann.source_id
    av.annotatable_type = ann.annotatable_type
    av.annotatable_id =   ann.annotatable_id
    av.attribute_id =     ann.attribute_id
    av.value =            ann.value
    av.value_type =       ann.value_type
    av.created_at =       ann.created_at
    av.updated_at =       ann.updated_at
    
    begin
      av.save!
      count += 1
    rescue Exception => ex
      puts "Failed on annotation ID: #{ann.id}. Error:"
      puts ex
    end
  end
end

Annotation::Version.record_timestamps = true

puts ""
puts "#{count} annotation objects sucessfully processed"
