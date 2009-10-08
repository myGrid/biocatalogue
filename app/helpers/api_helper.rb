# BioCatalogue: app/helpers/api_helper.rb
#
# Copyright (c) 2008-2009, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details.

module ApiHelper
  
  def xml_for_filters(builder, filters, filter_key)
    return nil if builder.nil? or filters.blank?
    
    filters.each do |f|
      
      builder.filter :urlValue => f["id"],
                     :name => f["name"],
                     :count => f['count'],
                     :resource => generate_include_filter_url(filter_key, f["id"]) do
                 
        xml_for_filters(builder, f["children"], filter_key)

      end
        
    end
  
  end

end