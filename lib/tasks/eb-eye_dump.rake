# BioCatalogue: lib/tasks/eb-eye_dump.rake
#
# Copyright (c) 2009, University of Manchester, The European Bioinformatics
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

require 'parsedate'
require 'libxml'
require 'fileutils'
require 'benchmark'

def truncate(text, *args)
  options = args.extract_options!
  unless args.empty?
    ActiveSupport::Deprecation.warn('truncate takes an option hash instead of separate ' + 'length and omission arguments', caller)

    options[:length] = args[0] || 30
    options[:omission] = args[1] || "..."
  end
  options.reverse_merge!(:length => 30, :omission => "...")

  if text
    l = options[:length] - options[:omission].mb_chars.length
    chars = text.mb_chars
    (chars.length > options[:length] ? chars[0...l] + options[:omission] : text).to_s
  end
end

def format_date(date)
  parsed_date = ParseDate.parsedate(date.to_s)
  date_to_time = Time.gm(*parsed_date)
  month = date_to_time.strftime("%b").upcase
  date_to_time.strftime("%d-#{month}-%Y")
end

def escape_lt_gt(text)
  text.gsub('<','&lt;').gsub('>','&gt;')
end

namespace :biocatalogue do
  namespace :ebeye do

    desc 'dump relevant information from BioCatalogue MySql DB in XML4dbDumps eb-eye format'
    task :dump => :environment do
      puts "Starts: #{Time.now}"
      Benchmark.bm(5) do |b|
        b.report("dump:") do
          puts "Starting XML dump..."
          datestamp = Time.now.strftime("%Y-%m-%d_%H-%M-%S")
          month = Time.now.strftime("%b").upcase
          date = Time.now.strftime("%d-#{month}-%Y")
          service_deployments = ServiceDeployment.find(:all)
          xml="<?xml version=\"1.0\" encoding=\"ISO-8859-1\"?>
<database>
  <name>biocatalogue</name>
  <description>The BioCatalogue is a registry of Life Science Web Services</description>
  <release>#{datestamp}</release>
  <release_date>#{date}</release_date>
  <entry_count>#{service_deployments.length}</entry_count>
  <entries>"
          for sd in service_deployments
            id = "#{sd.service_id}-#{sd.service.unique_code}"
            name = sd.service.name
            description = sd.service.description.nil? ? "" : truncate(sd.service.description.gsub(/[\t\n]+/,' ').squeeze(" "), :length => 300)
            description = escape_lt_gt(description)
            #description = truncate(sd.service.description.gsub(/[\t\n]+/,' ').squeeze(" "), :length => 300)
            tags = BioCatalogue::Annotations.get_tag_annotations_for_annotatable(sd.service)
            keywords = Array.new
            tags.each do |tag|
              tag_value = tag.value.nil? ? "" : tag.value.sub(/<http:\/\/www.mygrid.org.uk\/ontology#(\w+)>/,'\1') #strip off the url part of the mygrid ontology tags
              keywords.push(tag_value)
            end
            #location = sd.country
            provider = sd.provider_name
            #submitter = sd.submitter_name
            types = sd.service.service_types
            created_at = format_date(sd.created_at)
            updated_at = format_date(sd.updated_at)
            xml << "\n    <entry id=\"#{id}\" acc=\"#{id}\">"
            xml << "\n      <name>#{name}</name>"
            xml << "\n      <description>#{description}</description>"
            xml << "\n      <keywords>" + keywords.uniq.join(',') + "</keywords>"
            xml << "\n      <dates>"
            xml << "\n        <date type=\"creation\" value=\"#{created_at}\"/>"
            xml << "\n        <date type=\"last_modification\" value=\"#{updated_at}\"/>"
            xml << "\n      </dates>"
            xml << "\n      <additional_fields>"
            xml << "\n        <field name=\"service_types\">" + types.join(',') + "</field>"
            xml << "\n        <field name=\"provider\">#{provider}</field>"
            #xml << "\n        <submitter>#{submitter_name}</submitter>"
            #xml << "\n        <location>#{location}</location>"
            xml << "\n      </additional_fields>"
            xml << "\n    </entry>"
          end
          xml << "\n  </entries>"
          xml << "\n</database>"

          filename = "data/eb-eye/eb-eye_dump_#{datestamp}.xml"
          f = File.new(filename, "w+")
          f.write(xml)
          f.close

          # Validate the XML dump against the eb-eye xml4dumps schema

          # Parse schema as xml document
          schema_document = XML::Document.file('data/eb-eye/xml4dumps.xsd')

          # Prepare schema for validation
          schema = XML::Schema.document(schema_document)

          # Parse xml document to be validated
          #xml_dump = XML::Document.string(xml) ## create memory errors -> use Document.file instead
          xml_dump = XML::Document.file(filename)

          # Validate
          begin
            xml_dump.validate_schema(schema)
            puts "Validation successful ! Moving dump file..."
            FileUtils.cp filename, "data/eb-eye/eb-eye_dump_latest.xml"
          rescue
            puts "Validation Failed: " + $!
          end
        end
      end
      puts "Finishes: #{Time.now}"
    end
  end
end
