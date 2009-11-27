# BioCatalogue: app/views/services/index.atom.builder
#
# Copyright (c) 2009, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

atom_feed(:url => announcements_url(:format => :atom), :schema_date => "2009") do |feed|
  feed.title(@feed_title)
  
  unless @announcements.blank?
    feed.updated(@announcements.last.updated_at)
  
    @announcements.each do |announcement|
      feed.entry(announcement) do |entry|
        entry.title(display_name(announcement))
        entry.content(white_list(announcement.body), :type => 'html')
  
        entry.author do |author|
          author.name(display_name(announcement.user))
        end
      end
    end
  end
end
