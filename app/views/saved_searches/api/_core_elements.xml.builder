# BioCatalogue: app/views/saved_searches/api/_core_elements.xml.builder
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# <dc:title>
dc_xml_tag parent_xml, :title, xlink_title(saved_search)

# <name>
parent_xml.name saved_search.name

# <allScopes>
parent_xml.allScopes saved_search.all_scopes

# <query>
parent_xml.query saved_search.query

if show_scopes
  # <scopes>
  parent_xml.scopes do |scopes_node|
    saved_search.scopes.each { |scope| 
      scopes_node.scope do |s_node|
        # <scopeName>
        s_node.scopeName BioCatalogue::Search.scope_to_visible_search_type(scope.resource_type.underscore.pluralize)
        
        # <scopeUrlValue>
        s_node.scopeUrlValue scope.resource_type.underscore.pluralize
        
        # <scopeResourceType>
        s_node.scopeResourceType scope.resource_type.camelize.singularize
        
        # <filters>
        render :partial => "api/filtering/parameters", :locals => { :parent_xml => s_node, 
                                                                    :resource_type => scope.resource_type.camelize.pluralize, 
                                                                    :filters => scope.filters }
      end
    }
  end
end

if show_user
  # <user>
  parent_xml.user xlink_attributes(uri_for_object(saved_search.user), :title => xlink_title(saved_search.user)), 
                       :resourceType => "User",
                       :resourceName => saved_search.user.display_name
end

# <dcterms:created>
dcterms_xml_tag parent_xml, :created, saved_search.created_at
