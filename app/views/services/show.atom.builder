# BioCatalogue: app/views/services/show.atom.builder
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

                    
atom_feed :url => service_url(@service, :format => :atom), 
          :root_url => service_url(@service),
          :schema_date => "2009" do |feed|
  
  render :partial => 'shared/activity', 
         :locals => { :parent_feed => feed,
                      :feed_title => @feed_title,
                      :entries => activity_entries_for(@activity_logs_main, :detailed),
                      :item_url => service_url(@service, :anchor => "news") }
  
end