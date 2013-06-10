# This module provides the authorized? method which is needed by OAuth.

# authorized? basically tells OAuth that the private user resource or 
# the bit of functionality which is only available to logged in users
# can be accessed via the API using OAuth.

# This module should be included in the ApplicationController:
#   include OauthAuthorize

# To use it in the other controllers, simply put oauth_authorize
# followed by the list of actions you want to allow access.
#
# Example:
# oauth_authorize :create, :destroy, :index
# oauth_authorize :all

module OauthAuthorize
  extend ActiveSupport::Concern

   included do
      class_attribute :oauth_authorized_actions
  end


  module ClassMethods
    def oauth_authorize(*actions)
      self.oauth_authorized_actions ||= []
      self.oauth_authorized_actions += actions
    end
    
  end
  
protected

  def authorized?
    actions = self.class.oauth_authorized_actions
    actions ||= []
    return actions.include?(:all) || actions.include?(action_name.to_sym)
  end
  
end