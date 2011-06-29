# BioCatalogue: lib/bio_catalogue/auth.rb
#
# Copyright (c) 2009-2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

module BioCatalogue
  module Auth
    
    # The MAIN way in which authorisation should be handled within the system.
    #
    # This allows us to centralise all authorisation handling.
    #
    # Remember that authorisation should happen BOTH in:
    # - Views (e.g.: when determining whether to show actions buttons).
    # - Controllers (i.e.: to secure actions that require authorisation).
    #
    # *args are Hash pairs that are used to provide additional information used in authorisation. These can be:
    #   :rest_method - this is the RestMethod to which 'thing' is associated when 'thing' is a RestParameter or RestRepresentation.  For all other types of 'thing', this is optional.
    #   :tag_submitters - an Array of compound IDs specifying the submitters of the tag.
    def self.allow_user_to_curate_thing?(user, thing, *args)
      return false if user.nil? or thing.nil?
      
      # Curators are allowed to do everything!
      return true if user.is_curator?
      
      # get configuration options
      options = args.extract_options!

      case thing
        when :announcements
          # Above check for is_curator? is enough
        when :tag
          return true if options[:tag_submitters].include?("User:#{user.id}")
        when Annotation
          return true if thing.source == user
          return true if check_user_is_responsible_for_service_with_thing(user, thing)
        when Service
          return true if thing.all_responsibles.include?(user)
        when TestScript
          return true if thing.submitter_type == "User" && thing.submitter_id == user.id
          
          return true if check_user_is_responsible_for_service_with_thing(user, thing)
        when RestMethod
          return true if thing.submitter_type == "User" && thing.submitter_id == user.id
          
          return true if check_user_is_responsible_for_service_with_thing(user, thing)
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
          
          return true if check_user_is_responsible_for_service_with_thing(user, map)
        when ServiceProvider
          return thing.has_service_submitter? user
        else
          # Try to see if it belongs to a service and if so check that instead
          if thing.is_a? ActiveRecord::Base
            return true if check_user_is_responsible_for_service_with_thing(user, thing)
          end
      end
      
      return false
    end
    
    def self.allow_user_to_claim_thing?(user, thing, *params)
      case thing
        when Service
          return (!thing.all_responsibles.include?(user) && !existing_request_for_thing?(thing, user) )
        when ClientApplication, SavedSearch
          return thing.user == user
      end
      return false
    end
    
    
    # ========================================
    
    private
    
    def self.check_user_is_responsible_for_service_with_thing(user, thing)
      service = Mapper.map_object_to_associated_model_object(thing, "Service")
      return !service.nil? && service.all_responsibles.include?(user)
    end
    
    def self.existing_request_for_thing?(thing, user)
      return ResponsibilityRequest.exists?(:user_id => user.id,:subject_id => thing.id, :subject_type => thing.class.name )
    end
    
  end
end