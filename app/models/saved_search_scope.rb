# BioCatalogue: app/models/saved_search_scope.rb
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

class SavedSearchScope < ActiveRecord::Base

  # TODO: ENABLE_CACHE_MONEY
  # TODO: USE_EVENT_LOG

  belongs_to :saved_search
  
  # The :filters field is a serialised hash
  serialize :filters, Hash
  
  validates_presence_of :resource_type,
                        :filters
  
  validate :resource_type_in_search_scope
  
  validate :filters_are_valid_for_scope
  
  def to_json
    {
      "resource_type" => self.resource_type.camelize.singularize,
      "scope_url_value" => self.resource_type.underscore.pluralize,
      "scope_name" => BioCatalogue::Search.scope_to_visible_search_type(self.resource_type.underscore.pluralize),
      "filters" => self.filters
    }.to_json
  end
  
  def to_inline_json
    self.to_json
  end
  
private
  
  def resource_type_in_search_scope
    # make sure you store the name of the model as opposed to the url key
    self.resource_type = self.resource_type.camelize.singularize

    valid = BioCatalogue::Search::VALID_SEARCH_SCOPES.include?(self.resource_type.underscore.pluralize)
    errors.add("resource_type", "has to be a valid search scope") unless valid    
  end
  
  def filters_are_valid_for_scope
    scope = self.resource_type.underscore.pluralize
    valid = BioCatalogue::Filtering.are_filters_valid_for_scope?(self.filters, scope)
    errors.add("filters", "have to be valid for the given scope: #{scope}") unless valid
  end
  
end
