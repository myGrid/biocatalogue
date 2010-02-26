# BioCatalogue: app/controllers/categories_controller.rb
#
# Copyright (c) 2009-2010, University of Manchester, The European Bioinformatics
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details.

class CategoriesController < ApplicationController
  
  before_filter :disable_action, :only => [ :new, :create, :edit, :update, :destroy ]

  before_filter :parse_roots_only_param, :only => [ :index ]
  
  before_filter :find_category, :only => [ :show ]
  
  def index
    respond_to do |format|
      format.html { disable_action }
      format.xml # index.xml.builder
    end
  end
  
  def show
    respond_to do |format|
      format.html { disable_action }
      format.xml # show.xml.builder
    end
  end
  
  def services
    respond_to do |format|
      format.html { disable_action }
      format.xml { redirect_to(generate_include_filter_url(:cat, params[:id], "services", :xml)) }
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
  
end
