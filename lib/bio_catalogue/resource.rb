# BioCatalogue: lib/bio_catalogue/resource.rb
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# Module to abstract out any specific processing for the REST XML/JSON/etc API

module BioCatalogue
  module Resource
  
  def self.EXCLUDED_FLAG_CODES 
    [ "IM", "BL", "GG", "JE", "AQ", "MF" ].freeze
  end

  def self.icon_filename_for(thing)
    case thing
      when :activity
        "time.png"
      when :announcement, :announcements
        "transmit.png"
      when :spinner
        "spinner.gif"
      when :add
        "add.png"
      when :edit
        "pencil.gif"
      when :delete
        "delete.png"
      when :delete_faded
        "delete_faded.png"
      when :promote
        "promote.png"
      when :promote_faded
        "promote_faded.png"
      when :refresh
        "refresh.gif"
      when :expand
        "expand.png"
      when :collapse
        "collapse.png"
      when :plus
        "plus.png"
      when :minus
        "minus.png"
      when :help
        "help_icon.png"
      when :info
        "info.png"
      when :search
        "search.png"
      when :submit_service
        "add.png"
      when :favourite, :favourites
        "favourite.png"
      when :favourite_faded, :favourites_none
        "favourite_faded.png"
      when :views
        "eye.png"
      when :views_none
        "eye_faded.png"
      when :service, :services
        "service.png"
      when :annotation, :annotations
        "note.png"
      when :user, :member, :users, :members, :annotation_source_member
        "user.png"
      when :curator, :curators, :annotation_source_curator
        "user_suit.png"
      when :provider, :providers, :annotation_source_provider
        "group_gear.png"
      when :provider_document, :annotation_source_provider_document
        "page_white_code.png"
      when :registry, :registries, :annotation_source_registry
        "world_link.png"
      when :annotation_level
        "percentage.png"
      when :agent, :annotation_source_agent
        "server_connect.png"
      when :twitter
        "twitter_icon.png"
      when :twitter_follow
        "twitter_follow_me.gif"
      when :atom
        "feed_icon.png"
      when :atom_large
        "feed_icon_large.png"
      when :tag_add
        "add_tag.gif"
      when :tag_add_hover
        "add_tag_hover.gif"
      when :tag_add_inactive
        "add_tag_inactive.gif"
      when :user_edit
        "user_edit.gif"
      when :arrow_forward
        "red_arrow.gif"
      when :arrow_backward
        "red_arrow_left.gif"
      when :download
        "arrow-down_16.png"
      when :open_in_new_window
        "page_go.png"
      when :dropdown
        "dropdown.png"
      when :partners
        "group_link.png"
      when :check_updates
        "monitor_go.png"
      when :archive, :archived
        "cog_error.png"
      when :unarchive
        "cog_go.png"
      when :soap_service_change
        "cog_edit.png"
      when :monitoring_status_change
        "wrench.png"
      when :monitoring_status_change_failed
        "small-cross-sphere-16.png"
      when :monitoring_status_change_warning
        "small-pling-sphere-16.png"
      when :monitoring_status_change_passed
        "small-tick-sphere-16.png"
      when :monitoring_status_change_unchecked
        "small-query-sphere-16.png"
      when :latest
        "newspaper.png"
      when :search_by_data
        "page_white_magnify.png"
      else
        ''
    end
  end

  def self.flag_icon_path(code)
    return "" if self.EXCLUDED_FLAG_CODES.include? code
    return "" if code.blank?
    code = "GB" if code.upcase == "UK"

    begin
      return image_path("flags/#{code.downcase}.png")
    rescue
      return "/assets/flags/#{code.downcase}.png"
    end
  end

  end
end