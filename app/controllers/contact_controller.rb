# BioCatalogue: app/controllers/contact_controller.rb
#
# Copyright (c) 2008, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details.

class ContactController < ApplicationController
  # GET /contact
  def index
    respond_to do |format|
      format.html # index.html.erb
    end
  end
end
