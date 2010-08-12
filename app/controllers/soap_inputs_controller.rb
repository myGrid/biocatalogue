# BioCatalogue: app/controllers/soap_inputs_controller.rb
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details.


class SoapInputsController < ApplicationController
  
  before_filter :disable_action, :only => [ :index, :new, :create, :edit, :update, :destroy ]
  before_filter :disable_action_for_api, :except => [ :show, :annotations ]
  
  before_filter :find_soap_input, :only => [ :show, :annotations ]
  
  if ENABLE_SSL && Rails.env.production?
    ssl_allowed :all
  end

  def show
    respond_to do |format|
      format.html { redirect_to url_for_web_interface(@soap_input) }
      format.xml  # show.xml.builder
      format.json { render :json => @soap_input.to_json }
    end
  end
  
  def annotations
    respond_to do |format|
      format.html { disable_action }
      format.xml { redirect_to(generate_include_filter_url(:asin, @soap_input.id, "annotations", :xml)) }
      format.json { redirect_to(generate_include_filter_url(:asin, @soap_input.id, "annotations", :json)) }
    end
  end

  protected
  
  def find_soap_input
    @soap_input = SoapInput.find(params[:id], :include => :soap_operation)
  end
  
end
