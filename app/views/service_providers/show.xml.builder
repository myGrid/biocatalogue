# BioCatalogue: app/views/service_providers/show.xml.builder
#
# Copyright (c) 2009-2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# <?xml>
xml.instruct! :xml

# <serviceProvider>
render :partial => "service_providers/api/service_provider", 
       :locals => { :parent_xml => xml,
                    :service_provider => @service_provider,
                    :show_hostnames => true,
                    :is_root => true,
                    :show_related => true }
