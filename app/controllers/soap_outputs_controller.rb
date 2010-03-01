# BioCatalogue: app/controllers/soap_outputs_controller.rb
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details.


class SoapOutputsController < ApplicationController
  
  before_filter :disable_action, :only => [ :index, :new, :create, :edit, :update, :destroy ]
  before_filter :disable_action_for_api, :except => [ :show, :annotations ]
  
  before_filter :find_soap_output, :only => [ :show, :annotations ]
  
  def show
    respond_to do |format|
      format.html { redirect_to url_for_web_interface(@soap_output) }
      format.xml  # show.xml.builder
    end
  end
  
  def annotations
    respond_to do |format|
      format.html { disable_action }
      format.xml { redirect_to(generate_include_filter_url(:asout, @soap_output.id, "annotations", :xml)) }
      format.json { render :json => @soap_output.annotations.paginate(:page => @page, :per_page => @per_page).to_json }
    end
  end

  protected
  
  def find_soap_output
    @soap_output = SoapOutput.find(params[:id])
  end
  
end
