# BioCatalogue: app/views/api/_location.xml.builder
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# Defaults:
city = nil unless local_assigns.has_key?(:city)
country = nil unless local_assigns.has_key?(:country)

country_code = CountryCodes.code(country)

# <location>
parent_xml.location do
  
  # <city>
  parent_xml.city city
  
  # <country>
  parent_xml.country country
  
  # <iso3166CountryCode>
  parent_xml.iso3166CountryCode country_code
  
  # <flag>
  f = flag_icon_path(country_code)
  unless f.blank?
    parent_xml.flag nil, xlink_attributes(uri_for_path(f), :title => "Flag icon for this location")
  end
  
end