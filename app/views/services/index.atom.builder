# BioCatalogue: app/views/services/index.atom.builder
#
# Copyright (c) 2009, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

atom_feed :url => generate_filter_url(BioCatalogue::Util.duplicate_params(params), "services", :atom), 
          :root_url => generate_filter_url(BioCatalogue::Util.duplicate_params(params), "services"),
          :schema_date => "2009" do |feed|
  
  feed.title(@feed_title)
  feed.updated Time.now

  @services.each do |service|
    feed.entry(service) do |entry|
      entry.title(display_name(service))
      entry.content(service_body_for_feed(service), :type => 'html')

      entry.author do |author|
        author.name(display_name(service.submitter))
      end
    end
  end
  
end
