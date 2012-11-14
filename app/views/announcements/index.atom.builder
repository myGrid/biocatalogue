# BioCatalogue: app/views/announcements/index.atom.builder
#
# Copyright (c) 2009, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

atom_feed(:url => announcements_url(:format => :atom),
          :root_url => announcements_url,
          :schema_date => "2009") do |feed|
  
  feed.title(@feed_title)
  if @announcements.empty?
    feed.updated Time.now
  else
    feed.updated @announcements.first.updated_at
  end

  @announcements.each do |announcement|
    feed.entry(announcement) do |entry|
      entry.title(display_name(announcement))
      entry.content(white_list(simple_format(auto_link(announcement.body, :link => :all, :href_options => { :target => '_blank' }))), :type => 'html')

      entry.author do |author|
        author.name(display_name(announcement.user))
      end
    end
  end

end
