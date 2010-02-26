# BioCatalogue: app/views/users/api/_core_elements.xml.builder
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# <dc:title>
dc_xml_tag parent_xml, :title, xlink_title(user)

# <name>
parent_xml.name display_name(user, false)

# <affiliation>
parent_xml.affiliation user.affiliation

# <location>
render :partial => "api/location", :locals => { :parent_xml => parent_xml, :country => user.country } 

# <publicEmail>
parent_xml.publicEmail user.public_email

# <joined>
parent_xml.joined user.activated_at.iso8601
