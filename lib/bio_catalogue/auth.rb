# BioCatalogue: lib/bio_catalogue/auth.rb
#
# Copyright (c) 2009, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

module BioCatalogue
  module Auth
    
    # For now this checks if the user specified is the original submitter of the 
    # Service that the "thing" is referring to.
    def self.allow_user_to_curate_thing?(user, thing)
      return false if user.nil? or thing.nil?
      
      # Curators are allowed to do everything!
      return true if user.is_curator?
      
      case thing
        when Annotation
          return true if thing.source == user
        when Service
          return true if thing.submitter_type == "User" && thing.submitter_id == user.id
        else
          service = Mapper.map_object_to_associated_model_object(thing, "Service")
          return true if !service.nil? && service.submitter_type == "User" && service.submitter_id == user.id
      end
      
      return false
    end
    
  end
end