# BioCatalogue: lib/white_list_helper_extension.rb

# This extension is done to fix some issues with annotations not displaying 
# properly in the UI. 

# "<efet:eFetchRequest xmlns:efet="http://www.ncbi.nlm.nih.gov/soap/eutils/efetch_pubmed">"
# would appear in the UI as "<efet:eFetchRequest />"

# To allow for HTML elements, just add the element being ignored to one (or more)
# of the lists below.

WhiteListHelper.bad_tags.merge %w{}

WhiteListHelper.tags.merge %w{}

WhiteListHelper.attributes.merge %w{ xmlns:efet }

WhiteListHelper.protocols.merge %w{}
