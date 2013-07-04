# BioCatalogue: app/models/announcement.rb
#
# Copyright (c) 2009, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

class Announcement < ActiveRecord::Base
  
  if ENABLE_TRASHING
    acts_as_trashable
  end
  
  belongs_to :user

  validates_presence_of :user_id,
                        :title

  before_save :check_authorisation
  
  def self.latest(limit=5)
    self.all(              :order => "created_at DESC",
              :limit => limit)
  end
  
  def check_authorisation
    if !self.user_id.blank? and BioCatalogue::Auth.allow_user_to_curate_thing?(self.user, :announcements)
      return true
    else
      errors.add_to_base("Only admins and curators can create announcements")
      return false
    end
  end
  
end
