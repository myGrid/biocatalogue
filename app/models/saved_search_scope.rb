# BioCatalogue: app/models/saved_search_scope.rb
#
# Copyright (c) 2008, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

class SavedSearchScope < ActiveRecord::Base

  # TODO: ENABLE_CACHE_MONEY
  # TODO: USE_EVENT_LOG

  belongs_to :saved_search
  
  # The :filters field is a serialised hash
  serialize :filters, Hash
  
  validates_presence_of :resource,
                        :filters
  
  validate :resource_in_search_scope
  
  validate :filters_are_valid
  
  def to_json
    {
      "resource" => self.resource,
      "filters" => self.filters
    }.to_json
  end
  
  def to_inline_json
    self.to_json
  end
  
private
  
  def resource_in_search_scope
    valid = BioCatalogue::Search::VALID_SEARCH_SCOPES.include?(self.resource.underscore.pluralize)
    errors.add("resource", "has to be a valid search scope") unless valid
  end
  
  def filters_are_valid
    scope = self.resource.underscore.pluralize
    valid = BioCatalogue::Filtering.are_filters_valid_for_scope?(self.filters, scope)
    errors.add("filters", "have to be valid for the given scope: #{scope}") unless valid
  end
  
end
