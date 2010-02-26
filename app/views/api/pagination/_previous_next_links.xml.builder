# BioCatalogue: app/views/api/pagination/_previous_next_links.xml.builder
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

params_clone = BioCatalogue::Util.duplicate_params(params) unless local_assigns.has_key?(:params_clone)

# <previous>
unless page == 1
  parent_xml.previous previous_link_xml_attributes(resource_url_lambda.call(params_clone.merge(:page => (page - 1)))),
                      :resourceType => resource_type
end

# <next>
unless total_pages == 0 or total_pages == page 
  parent_xml.next next_link_xml_attributes(resource_url_lambda.call(params_clone.merge(:page => (page + 1)))),
                  :resourceType => resource_type
end