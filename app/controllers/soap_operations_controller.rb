# BioCatalogue: app/controllers/soap_operations_controller.rb
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details.


class SoapOperationsController < ApplicationController
  
  before_filter :disable_action, :only => [ :index, :new, :create, :edit, :update, :destroy ]
  before_filter :disable_action_for_api, :except => [ :show, :annotations ]
  
  before_filter :find_soap_operation, :only => [ :show, :annotations ]
  
  def show
    respond_to do |format|
      format.html { redirect_to url_for_web_interface(@soap_operation) }
      format.xml  # show.xml.builder
    end
  end
  
  def annotations
    respond_to do |format|
      format.html { disable_action }
      format.xml { redirect_to(generate_include_filter_url(:asop, @soap_operation.id, "annotations", :xml)) }
      format.json { render :json => @soap_operation.annotations.paginate(:page => @page, :per_page => @per_page).to_json }
    end
  end

  protected
  
  def find_soap_operation
    @soap_operation = SoapOperation.find(params[:id])
  end
  
end
