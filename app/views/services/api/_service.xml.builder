# BioCatalogue: app/views/services/api/_service.xml.builder
#
# Copyright (c) 2009-2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# Defaults:
is_root = false unless local_assigns.has_key?(:is_root)
show_core = true unless local_assigns.has_key?(:show_core)
show_summary = false unless local_assigns.has_key?(:show_summary)
show_deployments = false unless local_assigns.has_key?(:show_deployments)
show_variants = false unless local_assigns.has_key?(:show_variants)
show_monitoring = false unless local_assigns.has_key?(:show_monitoring)
show_related = false unless local_assigns.has_key?(:show_related)

# <service>
parent_xml.tag! "service",
                xlink_attributes(uri_for_object(service), :title => xlink_title(service)).merge(is_root ? xml_root_attributes : {}),
                :resourceType => "Service" do
  
  # Core elements
  if show_core
    render :partial => "services/api/core_elements", :locals => { :parent_xml => parent_xml, :service => service }
  end
          
  # <summary>
  if show_summary
    render :partial => "services/api/summary", :locals => { :parent_xml => parent_xml, :service => service }
  end
  
  # <deployments>
  if show_deployments
    render :partial => "services/api/deployments", :locals => { :parent_xml => parent_xml, :service => service }
  end
  
  # <variants>
  if show_variants
    render :partial => "services/api/variants", :locals => { :parent_xml => parent_xml, :service => service }
  end
  
  # <monitoring>
  if show_monitoring
    render :partial => "services/api/monitoring", :locals => { :parent_xml => parent_xml, :service => service }
  end
  
  # <related>
  if show_related
    render :partial => "services/api/related_links", :locals => { :parent_xml => parent_xml, :service => service }
  end

end