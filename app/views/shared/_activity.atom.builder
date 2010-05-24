# BioCatalogue: app/views/shared/_activity.atom.builder
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

parent_feed.title(feed_title)
parent_feed.updated entries.first.values.first.first[2]

entries.each do |e|
  e[e.keys.first].each do |i|
    parent_feed.entry(i, :url => item_url) do |entry|    
      entry.title(truncate(strip_tags(i[0]), :length => 60))
      entry.content(i[0], :type => 'html')
      entry.updated(i[2].xmlschema)
    end
  end
end
