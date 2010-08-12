# BioCatalogue: app/controllers/termsofuse_controller.rb
#
# Copyright (c) 2008, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details.

class TermsofuseController < ApplicationController
  
  before_filter :disable_action_for_api
  
  if ENABLE_SSL && Rails.env.production?
    ssl_allowed :all
  end

  # GET /termsofuse
  def index
    respond_to do |format|
      format.html # index.html.erb
    end
  end
end
