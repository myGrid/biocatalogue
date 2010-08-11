# BioCatalogue: app/views/rest_methods/api/_outputs.xml.builder
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# <parameters>
parent_xml.tag! "parameters" do |node|
                  
  rest_method.response_parameters.each do |parameter|
    # <restParameter>
    render :partial => "rest_parameters/api/inline_item", :locals => { :parent_xml => node, :rest_parameter => parameter }
  end
  
end

# <representations>
parent_xml.tag! "representations" do |node|
                  
  rest_method.response_representations.each do |representation|
    # <restRepresentation>
    render :partial => "rest_representations/api/inline_item", :locals => { :parent_xml => node, :rest_representation => representation }
  end
  
end