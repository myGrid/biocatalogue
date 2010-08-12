# BioCatalogue: app/controllers/categories_controller.rb
#
# Copyright (c) 2009-2010, University of Manchester, The European Bioinformatics
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details.

class CategoriesController < ApplicationController
  
  before_filter :disable_action, :only => [ :new, :create, :edit, :update, :destroy ]

  before_filter :parse_roots_only_param, :only => [ :index ]
  
  before_filter :find_category, :only => [ :show ]
  before_filter :find_categories, :only => [ :index ]
  
  def index
    respond_to do |format|
      format.html { disable_action }
      format.xml # index.xml.builder
      format.json { render :json => BioCatalogue::Api::Json.index("categories", @json_api_params, @categories, true).to_json }
    end
  end
  
  def show
    respond_to do |format|
      format.html { disable_action }
      format.xml # show.xml.builder
      format.json { render :json => @category.to_json }
    end
  end
  
  def services
    respond_to do |format|
      format.html { disable_action }
      format.xml { redirect_to(generate_include_filter_url(:cat, params[:id], "services", :xml)) }
      format.json { redirect_to(generate_include_filter_url(:cat, params[:id], "services", :json)) }
    end
  end
  
  protected
  
  def parse_roots_only_param
    @roots_only = if params[:roots_only].blank?
      true
    else
      if params[:roots_only] == "true"
        true
      else
        false
      end
    end
  end
  
  def find_category
    @category = Category.find_by_id(params[:id])
    raise ActiveRecord::RecordNotFound if @category.nil?
  end
  
  def find_categories
    @categories = Category.paginate(:page => @page,
                                    :per_page => @per_page)
  end
end
