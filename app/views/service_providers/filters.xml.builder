# BioCatalogue: app/views/service_providers/filters.xml.builder
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# <?xml>
xml.instruct! :xml

# <filters>
render :partial => "api/filtering/filters", :locals => { :parent_xml => xml, :resource_type => "ServiceProviders" }
