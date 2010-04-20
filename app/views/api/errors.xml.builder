# BioCatalogue: app/views/error/errors.xml.builder
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# <?xml>
xml.instruct! :xml

# <errors>
xml.tag! "errors", 
         xml_root_attributes, 
         :resourceType => "Errors" do
  
  # <error> *
  
  if defined? @errors and !@errors.nil?
    @errors.each do | error |
      xml.error error
    end
  end
  
end