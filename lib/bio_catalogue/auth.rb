# BioCatalogue: lib/bio_catalogue/auth.rb
#
# Copyright (c) 2009-2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

module BioCatalogue
  module Auth
    
    # For now this checks if the user specified is the original submitter of the 
    # Service that the "thing" is referring to.
    #
    # CONFIGURATION OPTIONS
    # rest_method: this is the RestMethod to which 'thing' is associated when 'thing' is a RestParameter or RestRepresentation.  For all other types of 'thing', this is optional.
    def self.allow_user_to_curate_thing?(user, thing, *args)
      return false if user.nil? or thing.nil?
      
      # Curators are allowed to do everything!
      return true if user.is_curator?
      
      # get configuration options
      options = args.extract_options!

      case thing
        when :announcements
          # Above check for is_curator? is enough
        when Annotation
          return true if thing.source == user
        when Service
          return true if thing.submitter_type == "User" && thing.submitter_id == user.id
        when TestScript
          return true if thing.submitter_type == "User" && thing.submitter_id == user.id
          
          return true if check_user_owns_service_with_thing(user, thing)
        when RestMethod
          return true if thing.submitter_type == "User" && thing.submitter_id == user.id
          
          return true if check_user_owns_service_with_thing(user, thing)
        when RestParameter, RestRepresentation
          return false if options[:rest_method].nil? || options[:rest_method].class.to_s != "RestMethod"
          
          return true if options[:rest_method].submitter_id == user.id # user owns this RestMethod

          if thing.class.to_s == "RestParameter"
            # can only edit the method-parameter maps, NOT the params themselves
            map = options[:rest_method].rest_method_parameters.find_by_rest_parameter_id(thing.id)
          else # RestRepresentation
            # can only edit the method-representations maps, NOT the representations themselves
            map = options[:rest_method].rest_method_representations.find_by_rest_representation_id(thing.id)
          end
          return true if user.id == map.submitter_id && thing.submitter_type == "User"
          
          return true if check_user_owns_service_with_thing(user, map)
        else
          # Try to see if it belongs to a service and if so check that instead
          if thing.is_a? ActiveRecord::Base
            return true if check_user_owns_service_with_thing(user, thing)
          end
      end
      
      return false
    end
    
    
    # ========================================
    
    private
    
    def self.check_user_owns_service_with_thing(user, thing)
      service = Mapper.map_object_to_associated_model_object(thing, "Service")
      return !service.nil? && service.submitter_type == "User" && service.submitter_id == user.id
    end
    
  end
end