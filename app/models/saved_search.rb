# BioCatalogue: app/models/saved_search.rb
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

class SavedSearch < ActiveRecord::Base
    
  # TODO: USE_EVENT_LOG
  
  has_many :saved_search_scopes,
           :dependent => :destroy

  belongs_to :user

  validates_presence_of :name
  
  validates_existence_of :user   # User must exist in the db beforehand.

  validates_inclusion_of :all_scopes, :in => [ true, false ]
  
  validate :combinatory_logic
  
  # Alias for saved_search_scopes
  def scopes
    self.saved_search_scopes
  end
  
  def add_scope(resource_type, filters)
    @scopes_are_empty = false
    self.saved_search_scopes.build(:resource_type => resource_type, :filters => filters)
  end
  
  def to_json
    generate_json_and_make_inline(false)
  end
  
  def to_inline_json
    generate_json_and_make_inline(true)
  end
  
private

  def combinatory_logic
    if self.all_scopes
      # scopes==optional && query==mandatory
      errors.add("query", "can't be blank when :all_scopes is 'true'") if self.query.blank?
    else
      # scopes==mandatory && query==optional
      if self.id.blank? # creation
        @scopes_are_empty = true if @scopes_are_empty.nil?
      else # update
        @scopes_are_empty = self.scopes.blank? 
      end
      errors.add("scopes", "can't be blank when :all_scopes is 'false'") if @scopes_are_empty
    end
  end

  def generate_json_and_make_inline(make_inline)      
    data = {
      "saved_search" => {
        "name" => self.name,
        "all_scopes" => self.all_scopes,
        "query" => self.query,
        "user" => BioCatalogue::Api.uri_for_object(self.user),
        "scopes" => BioCatalogue::Api::Json.collection(self.scopes, true),
        "created_at" => self.created_at.iso8601
      }
    }

    unless make_inline
      data["saved_search"]["self"] = BioCatalogue::Api.uri_for_object(self)
      return data.to_json
    else
      data["saved_search"]["resource"] = BioCatalogue::Api.uri_for_object(self)
      return data["saved_search"].to_json
    end
  end
  
end
