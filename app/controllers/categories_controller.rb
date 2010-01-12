# BioCatalogue: app/controllers/categories_controller.rb
#
# Copyright (c) 2009, University of Manchester, The European Bioinformatics
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details.

class CategoriesController < ApplicationController
  
  before_filter :disable_action, :only => [ :new, :create, :edit, :update, :destroy ]
  
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
  
  protected
  
  def find_category
    @category = Category.find_by_id(params[:id])
    raise ActiveRecord::RecordNotFound if @category.nil?
  end
  
end
