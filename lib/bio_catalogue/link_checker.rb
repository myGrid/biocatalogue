module BioCatalogue
  module LinkChecker

    #!/usr/bin/env ruby
    #
    # This script generate a list of links found in descriptions and other annotations
    # and checks the status of the links. It then produces a yaml file containing links which
    # might no longer be accessible.
    # This is stored in data/#{RAILS_ENV}_reports/links_checker_report.yml


    require 'optparse'
    require 'benchmark'
    require 'pp'

    class LinksChecker

      attr_accessor :options

      # Find all the services that have not been archived from the database
      # and extract any url from the descriptions and other annotatable attributes
      # of the service and its components. Then check if these links are accessible
      # or not. Flag the ones that are not accessible and generate an html report of
      # those.

      def run
        @all_links           = []
        @all_data_with_links = []
        conditions           = 'archived_at IS NULL'
        Service.where(conditions).each do |service|
          puts "Searching links for service : #{service.name}"
          @all_links.concat(links_for_service(service))
          @all_data_with_links << links_for_service_h(service) unless links_for_service_h(service).empty?
        end
        @checked_links = self.check_all(@all_links.uniq)
        save_report([@all_data_with_links, @checked_links])
      end

      def save_report report_values
        reports_dir = Rails.root.join('data', "#{Rails.env}_reports")
        unless Dir.exist?(reports_dir)
           Dir.mkdir(reports_dir)
        end
        links_checker_file = reports_dir.to_s + '/links_checker_report.yml'
        File.open(links_checker_file, File::WRONLY|File::CREAT) {|file| file.write(report_values.to_yaml)}
      end

      protected


      # Generates a list of child object of a Service for which
      # links need to be checked. Return the empty list if there
      # are no child objects.
      #
      # param Service object for which links need to be checked < br/>
      #
      # return List of child objects of the service for which links
      # need to be checked. Default is empty list
      #
      def service_annotatables(service)
        annotatables     = []
        service_instance = service.latest_version.service_versionified
        annotatables.concat(service.service_deployments)
        annotatables << service_instance
        if service_instance.respond_to?(:soap_operations)
          annotatables.concat(service_instance.soap_operations)
          service_instance.soap_operations.each do |op|
            annotatables.concat(op.soap_inputs)
            annotatables.concat(op.soap_outputs)
          end
        end
        if service_instance.respond_to?(:rest_resources)
          annotatables.concat(service_instance.rest_resources)
        end
        return annotatables
      end

      # Get all annotations attached to a given object for a
      # given attribute.
      #
      # param Parent object to which the annotations are attached.
      # param Attribute of the parent object that is annotated.
      #
      # return List of the values of those annotations. Defualt is empty list<br />
      def non_provider_annotations(parent, attr='description')
        if parent.respond_to?(:annotations)
          return  parent.annotations.collect{|a| a.value if a.attribute.name.downcase == attr}.compact
        end
        return []
      end

      def get_links_from_text(text)
        pieces = text.split
        pieces.collect!{ |p| self.parse_link(p) if p.match('http|www')}.compact
      end

      # This is attempt to put links into format.
      # It is anecdotal as it is designed looking at the
      # the data. May not work for all links
      def parse_link(link)
        return nil if link.nil?
        return nil if link.split('?').size > 1 # skip links with parameters
        while link.match('^\(|^\[')  # remove leading '(', '['
          link = link[1, (link.size-1)]
        end
        while link.match('\)$|\.$|\\$')
          link = link[0, (link.size-1)]
        end
        if link.match('^www')
          link = 'http://' + link
        end

        if link.match("^href|^HREF")
          pieces = link.split('"')
          pieces = link.split("'") if pieces.size == 1
          link = pieces.collect!{ |p| p if p.match('http|www')}.compact.first
        end
        return link if link.match('^http')
        return nil
      end

      def links_for_annotatable(annotatable)
        links = []
        if annotatable.respond_to?(:description)
          if annotatable.description
            links.concat(self.get_links_from_text(annotatable.description))
          end
          self.non_provider_annotations(annotatable).each do |ann|
            links.concat(self.get_links_from_text(ann.ann_content))
          end
          if annotatable.is_a?(SoapService) || annotatable.is_a?(RestService)
            self.non_provider_annotations(annotatable, 'documentation_url').each do |ann|
              links.concat(self.get_links_from_text(ann.ann_content))
            end
          end
        end
        #puts "Found #{links.count} links for #{annotatable.class.name + annotatable.id.to_s}"
        #pp links
        return links
      end

      def links_for_annotatable_h(annotatable)
        links = {}
        unless self.links_for_annotatable(annotatable).empty?
          links[annotatable.class.name+'_'+(annotatable.id.to_s)] = self.links_for_annotatable(annotatable)
        end
        return links
      end

      def links_for_service(service)
        links   = []
        self.service_annotatables(service).each  do |ann|
          links.concat(self.links_for_annotatable(ann))
        end
        return links
      end

      # Returns a hash of services and the list of links
      # found in the description of service components like soap
      # operations and inputs & outputs.
      # Has structure:
      #  { service_name+id => [ { component_class+id => [ list of urls]},
      #                          { component_class+id => [ list of urls]} ]}
      #
      # Example:
      #     {"WSDBFetchServerService2701"=>
      #                [{"SoapOperation19687"=>
      #                       ["http://www.ebi.ac.uk/Tools/webservices/services/dbfetch#fetchbatch_db_ids_format_style)."]},
      #                 {"SoapOperation19686"=>
      #                       ["http://www.ebi.ac.uk/Tools/webservices/services/dbfetch#fetchdata_query_format_style)."]},
      #                 {"SoapOperation19685"=>
      #                       ["http://www.ebi.ac.uk/Tools/webservices/services/dbfetch#getdbformats_db)."]},
      #                 {"SoapOperation19690"=>
      #                       ["http://www.ebi.ac.uk/Tools/webservices/services/dbfetch#getformatstyles_db_format)."]},
      #                 {"SoapOperation19688"=>
      #                       ["http://www.ebi.ac.uk/Tools/webservices/services/dbfetch#getsupporteddbs)."]},
      #                 {"SoapOperation19689"=>
      #                       ["http://www.ebi.ac.uk/Tools/webservices/services/dbfetch#getsupportedformats)."]},
      #                 {"SoapOperation19691"=>
      #                       ["http://www.ebi.ac.uk/Tools/webservices/services/dbfetch#fetchdata_query_format_style)."]}
      #                 ]
      #       }
      #
      #

      def links_for_service_h(service)
        links   = []
        s_links = {}
        self.service_annotatables(service).each do |ann|
          unless links_for_annotatable_h(ann).empty?
            links << links_for_annotatable_h(ann)
          end
        end
        s_links[service.name+'_'+(service.id.to_s)] = links unless links.empty?
        return s_links
      end

      #check the accessibility of a url. Follows up to 3 redirects
      def accessible?(url)
        return BioCatalogue::AvailabilityCheck::URLCheck.new(url).available?
      end

      def check_all(links=[])
        checked = {}
        links.each do |link|
          checked[link] = self.accessible?(link)
        end
        return checked
      end

    end

  end
end