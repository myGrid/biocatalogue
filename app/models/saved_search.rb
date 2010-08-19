# BioCatalogue: app/models/saved_search.rb
#
# Copyright (c) 2008, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

class SavedSearch < ActiveRecord::Base
    
  # TODO: USE_EVENT_LOG
  
  @scopes_are_empty = true # keep track of whether scopes have been added or not

  has_many :saved_search_scopes,
           :dependent => :destroy

  belongs_to :user
  
  validates_existence_of :user   # User must exist in the db beforehand.

  validates_inclusion_of :unbound, :in => [ true, false ]
  
  validate :combinatory_logic
  
  # Alias for saved_search_scopes
  def scopes
    self.saved_search_scopes
  end
  
  def add_scope(resource, filters)
    @scopes_are_empty = false
    self.saved_search_scopes.build(:resource => resource, :filters => filters)
  end
  
  def to_json
    generate_json_and_make_inline(false)
  end
  
  def to_inline_json
    generate_json_and_make_inline(true)
  end
  
private

  def combinatory_logic
    if self.unbound==true
      # scopes==optional && query==mandatory
      errors.add("query", "can't be blank when :unbound is 'true'") if self.query.blank?
    else
      # scopes==mandatory && query==optional
      @scopes_are_empty = self.scopes.blank? if self.id # an id that is not nil is the signifies an update (not creation)
      errors.add("scopes", "can't be blank when :unbound is 'false'") if @scopes_are_empty
    end
  end

  def generate_json_and_make_inline(make_inline)      
    data = {
      "saved_search" => {
        "name" => self.name,
        "unbound" => self.unbound,
        "query" => self.query,
        "user" => BioCatalogue::Api.uri_for_object(self.user),
        "created_at" => self.created_at.iso8601
      }
    }

    unless make_inline
      data["saved_search"]["scopes"] = BioCatalogue::Api::Json.collection(self.scopes, true)
      data["saved_search"]["self"] = BioCatalogue::Api.uri_for_object(self)
      return data.to_json
    else
      data["saved_search"]["resource"] = BioCatalogue::Api.uri_for_object(self)
      return data["saved_search"].to_json
    end
  end
  
end
