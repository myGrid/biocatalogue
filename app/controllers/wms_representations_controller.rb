# BioCatalogue: app/controllers/wms_representations_controller.rb
#
# Copyright (c) 2009-2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details.

class WmsRepresentationsController < ApplicationController
  before_filter :disable_action, :only => [ :index, :edit ]
  before_filter :disable_action_for_api, :except => [ :show, :annotations ]

  before_filter :login_or_oauth_required, :except => [ :show, :annotations ]

  before_filter :find_wms_method, :except => [ :destroy, :show, :annotations ]

  before_filter :find_wms_representation, :only => [ :destroy, :show, :annotations ]
  before_filter :find_wms_methods, :only => [ :show ]

  before_filter :authorise, :except => [ :show, :annotations ]

  def show
    respond_to do |format|
      format.html { redirect_to url_for_web_interface(@wms_representation) }
      format.xml  # show.xml.builder
      format.json { render :json => @wms_representation.to_json }
    end
  end

  def annotations
    respond_to do |format|
      format.html { disable_action }
      format.xml { redirect_to(generate_include_filter_url(:arr, @wms_representation.id, "annotations", :xml)) }
      format.json { redirect_to(generate_include_filter_url(:arr, @wms_representation.id, "annotations", :json)) }
    end
  end

  def new_popup
    respond_to do |format|
      format.js { render :layout => false }
    end
  end

  def add_new_representations
    results = @wms_method.add_representations(params[:wms_representations], current_user, :http_cycle => params[:http_cycle])

    respond_to do |format|
      unless results[:created].blank?
        flash[:notice] ||= "".html_safe
        flash[:notice] += "The following representations were successfully created:<br/>".html_safe
        flash[:notice] += results[:created].to_sentence
        flash[:notice] += "<br/><br/>".html_safe
      end

      unless results[:updated].blank?
        flash[:notice] ||= "".html_safe
        flash[:notice] += "The following parameters already exist:<br/>".html_safe
        flash[:notice] += results[:updated].to_sentence
      end

      unless results[:error].blank?
        flash[:error] = "The following representations could not be added:<br/>".html_safe
        flash[:error] += results[:error].to_sentence
      end

      format.html { redirect_to @wms_method }
    end
  end

  def destroy
    success_msg = "Representation <b>".html_safe + @wms_representation.content_type + "</b> has been deleted".html_safe
    url_to_redirect_to = get_redirect_url()

    destroy_method_rep_map()

    is_not_used = WmsMethodRepresentation.all(:conditions => {:wms_representation_id => @wms_representation.id}).empty?
    @wms_representation.destroy if is_not_used

    respond_to do |format|
      flash[:notice] = success_msg
      format.html { redirect_to url_to_redirect_to }
      format.xml  { head :ok }
    end
  end


  # ========================================


  protected

  def authorise
    auth_on_meth = BioCatalogue::Auth.allow_user_to_curate_thing?(current_user, @wms_method)
    auth_on_rep = BioCatalogue::Auth.allow_user_to_curate_thing?(current_user, @wms_representation, :wms_method => WmsMethod.find(params[:wms_method_id]))

    unless auth_on_rep || auth_on_meth
      error_to_back_or_home("You are not allowed to perform this action")
      return false
    end

    return true
  end


  # ========================================


  private

  def find_wms_method
    @wms_method = WmsMethod.find(params[:wms_method_id])
  end

  def find_wms_representation
    @wms_representation = WmsRepresentation.find(params[:id])
  end

  def find_wms_methods
    @wms_methods = []

    @wms_representation.wms_method_representations.each { |map|
      method = WmsMethod.find(map.wms_method_id, :include => [ :wms_resource, :wms_service ])
      @wms_methods << method if method && !@wms_methods.include?(method)
    }

    @wms_methods.uniq!
  end

  def get_redirect_url()
    method_rep_map = WmsMethodRepresentation.first(
        :conditions => {:wms_representation_id => @wms_representation.id,
                        :wms_method_id => params[:wms_method_id]})

    wms_method = WmsMethod.find(params[:wms_method_id])

    return wms_method_url(wms_method)
  end

  def destroy_method_rep_map() # USES params[:wms_method_id], params[:http_cycle], and @wms_representation.id
    method_rep_map = WmsMethodRepresentation.first(
        :conditions => {:wms_representation_id => @wms_representation.id,
                        :wms_method_id => params[:wms_method_id],
                        :http_cycle => params[:http_cycle]})
    method_rep_map.destroy
  end

end
