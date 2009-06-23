# BioCatalogue: app/views/services/index.atom.builder
#
# Copyright (c) 2009, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

atom_feed(:url => services_url(:format => :atom), :schema_date => "2009") do |feed|
  feed.title("BioCatalogue.org - Latest Services")
  feed.updated(@services.empty? ? Time.now.utc : @services.sort{|x,y| y.updated_at <=> x.updated_at}.first.updated_at)

  for service in @services
    feed.entry(service) do |entry|
      entry.title(service.name)
      entry.content(service_body_for_feed(service), :type => 'html')

      entry.author do |author|
        author.name(display_name(service.submitter))
      end
    end
  end
end
