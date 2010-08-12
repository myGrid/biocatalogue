# BioCatalogue: app/controllers/annotation_attributes_controller.rb
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details.

class AnnotationAttributesController < ApplicationController
  
  before_filter :disable_action, :only => [ :new, :create, :edit, :update, :destroy ]
  
  before_filter :find_annotation_attributes, :only => [ :index ]
  
  before_filter :find_annotation_attribute, :only => [ :show, :annotations ]
  
  if ENABLE_SSL && Rails.env.production?
    ssl_allowed :all
  end

  def index
    respond_to do |format|
      format.html { disable_action }
      format.xml # index.xml.builder
      format.json { render :json => BioCatalogue::Api::Json.index("annotation_attributes", @json_api_params, @annotation_attributes, false).to_json }
    end
  end
  
  def show
    respond_to do |format|
      format.html { disable_action }
      format.xml # show.xml.builder
      format.json { render :json => @annotation_attribute.to_json }
    end
  end
  
  def annotations
    respond_to do |format|
      format.html { disable_action }
      format.xml { redirect_to(generate_include_filter_url(:attrib, @annotation_attribute.id, "annotations", :xml)) }
      format.json { redirect_to(generate_include_filter_url(:attrib, @annotation_attribute.id, "annotations", :json)) }
    end
  end
  
  protected
  
  def find_annotation_attributes
    @annotation_attributes = AnnotationAttribute.paginate(:page => @page, :per_page => @per_page)
  end
  
  def find_annotation_attribute
    @annotation_attribute = AnnotationAttribute.find(params[:id])
  end
  
end
