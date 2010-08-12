require 'oauth/controllers/provider_controller'
class OauthController < ApplicationController
  include OAuth::Controllers::ProviderController
  
  before_filter :disable_action_for_api

  if ENABLE_SSL && Rails.env.production?
    ssl_required :all
  end

  # Override this to match your authorization page form
  # It currently expects a checkbox called authorize
  # def user_authorizes_token?
  #   params[:authorize] == '1'
  # end
    
end
