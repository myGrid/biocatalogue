# BioCatalogue: app/controllers/wms_parameters_controller.rb
#
# Copyright (c) 2009-2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details.

class WmsParametersController < ApplicationController

  before_filter :disable_action, :only => [ :index, :edit, :localise_globalise_parameter ]
  before_filter :disable_action_for_api, :except => [ :show, :annotations ]

  before_filter :login_or_oauth_required, :except => [ :show, :annotations ]

  before_filter :find_wms_method, :only => [ :new_popup, :add_new_parameters ]

  before_filter :find_wms_parameter, :except => [ :new_popup, :add_new_parameters ]
  before_filter :find_wms_methods, :only => [ :show ]

  before_filter :authorise, :except => [ :show, :annotations ]

  def show
    respond_to do |format|
      format.html { redirect_to url_for_web_interface(@wms_parameter) }
      format.xml  # show.xml.builder
      format.json { render :json => @wms_parameter.to_json }
    end
  end

  def annotations
    respond_to do |format|
      format.html { disable_action }
      format.xml { redirect_to(generate_include_filter_url(:arp, @wms_parameter.id, "annotations", :xml)) }
      format.json { redirect_to(generate_include_filter_url(:arp, @wms_parameter.id, "annotations", :json)) }
    end
  end

  def update_default_value
    # sanitize user input to make it have characters that are only fit for URIs
    params[:new_value].chomp!
    params[:new_value].strip!
    default_value = CGI::escape(params[:new_value])

    do_not_proceed = default_value.blank? || params[:old_value]==default_value

    unless do_not_proceed
      @wms_parameter.default_value = default_value
      @wms_parameter.save!
    end

    respond_to do |format|
      if do_not_proceed
        flash[:error] = "An error occured while trying to update the default value for parameter <b>".html_safe + @wms_parameter.name + "</b>".html_safe
      else
        flash[:notice] = "The default value for parameter <b>".html_safe + @wms_parameter.name + "</b> has been updated".html_safe
      end
      format.html { redirect_to get_redirect_url }
      format.xml  { head :ok }
    end
  end

  def edit_default_value_popup
    respond_to do |format|
      format.js { render :layout => false }
    end
  end

  def remove_default_value
    @wms_parameter.default_value = nil
    @wms_parameter.save!

    respond_to do |format|
      flash[:notice] = "The default value has been deleted from parameter <b>".html_safe + @wms_parameter.name + "</b>".html_safe

      format.html { redirect_to get_redirect_url }
      format.xml  { head :ok }
    end
  end

  def inline_add_default_value
    # sanitize user input to make it have characters that are only fit for URIs
    params[:default_value].chomp!
    params[:default_value].strip!
    default_value = CGI::escape(params[:default_value])

    unless default_value.blank?
      @wms_parameter.default_value = default_value
      @wms_parameter.save!
    end

    respond_to do |format|
      format.html { render :partial => "wms_parameters/#{params[:partial]}",
                           :locals => { :parameter => @wms_parameter,
                                        :wms_method_id => params[:wms_method_id]} }
      format.js { render :partial => "wms_parameters/#{params[:partial]}",
                         :locals => { :parameter => @wms_parameter,
                                      :wms_method_id => params[:wms_method_id] } }
    end
  end

  def update_constrained_options
    params[:new_constrained_options].chomp!
    params[:new_constrained_options].strip!

    do_not_proceed = params[:new_constrained_options].blank? ||
        params[:old_constrained_options]==params[:new_constrained_options] ||
        @wms_parameter.constrained_options.include?(params[:new_constrained_options])

    unless do_not_proceed
      @wms_parameter.constrained_options = params[:new_constrained_options].split("\n")
      @wms_parameter.constrained_options.each { |c| c.strip! }
      @wms_parameter.constrained = 1
      @wms_parameter.save!
    end

    respond_to do |format|
      if do_not_proceed
        flash[:error] = "An error occured while trying to update constraint for parameter <b>".html_safe + @wms_parameter.name +  "</b>".html_safe
      else
        flash[:notice] = "Constrained values for parameter <b>".html_safe + @wms_parameter.name + "</b> have been updated".html_safe
      end
      format.html { redirect_to get_redirect_url }
      format.xml  { head :ok }
    end
  end

  def edit_constrained_options_popup
    @old_constrained_options = @wms_parameter.constrained_options.join("\n")

    respond_to do |format|
      format.js { render "_edit_constrained_options_popup", :layout => false }
    end
  end

  def remove_constrained_options
    @wms_parameter.constrained_options = []
    @wms_parameter.constrained = 0
    @wms_parameter.save!

    respond_to do |format|
      flash[:notice] = "Constrained values have been deleted from parameter <b>".html_safe + @wms_parameter.name + "</b>".html_safe

      format.html { redirect_to get_redirect_url }
      format.xml  { head :ok }
    end
  end

  def new_popup
    respond_to do |format|
      format.js { render :layout => false }
    end
  end

  def add_new_parameters
    results = @wms_method.add_parameters(params[:wms_parameters], current_user, :make_local => true)

    respond_to do |format|
      unless results[:created].blank?
        flash[:notice] ||= "".html_safe
        flash[:notice] += "The following parameters were successfully created:<br/>".html_safe
        flash[:notice] += results[:created].to_sentence.html_safe
        flash[:notice] += "<br/><br/>".html_safe
      end

      unless results[:updated].blank?
        flash[:notice] ||= "".html_safe
        flash[:notice] += "The following parameters already exist and have been updated:<br/>".html_safe
        flash[:notice] += results[:updated].to_sentence
      end

      unless results[:error].blank?
        flash[:error] = "The following parameters could not be added:<br/>".html_safe
        flash[:error] += results[:error].to_sentence.html_safe
      end

      format.html { redirect_to @wms_method }
    end
  end

  def localise_globalise_parameter
    url_to_redirect_to = get_redirect_url()

    param_name = @wms_parameter.name

    # destroy map
    destroy_method_param_map() # this is the map for the parameter being linked/unlinked

    is_not_used = WmsMethodParameter.all(:conditions => {:wms_parameter_id => @wms_parameter.id}).empty?
    @wms_parameter.destroy if is_not_used

    # make unique or generic
    associated_method = WmsMethod.find(params[:wms_method_id])
    if params[:make_local] # make the param unique to the method
      associated_method.add_parameters(param_name, current_user, :make_local => true)
    else # use an already existing param OR create one as needed
      associated_method.add_parameters(param_name, current_user)
    end

    respond_to do |format|
      if params[:make_local]
        success_msg = ("Parameter <b>" + param_name + "</b> now has a copy unique for endpoint <b>" + associated_method.display_endpoint + "</b>").html_safe
      else
        success_msg = ("Parameter <b>" + param_name + "</b> for endpoint <b>" + associated_method.display_endpoint + "</b> is now global").html_safe
      end

      format.html { redirect_to url_to_redirect_to }
      format.xml  { head :ok }
    end
  end

  def make_optional_or_mandatory
    @wms_parameter.required = !@wms_parameter.required
    @wms_parameter.save!

    respond_to do |format|
      flash[:notice] = "Parameter <b>".html_safe + @wms_parameter.name + "</b> is now ".html_safe + (@wms_parameter.required ? 'mandatory':'optional')
      format.html { redirect_to get_redirect_url }
      format.xml  { head :ok }
    end
  end

  def destroy
    success_msg = "Parameter <b>".html_safe + @wms_parameter.name + "</b> has been deleted".html_safe

    url_to_redirect_to = get_redirect_url()

    destroy_method_param_map()

    is_not_used = WmsMethodParameter.all(:conditions => {:wms_parameter_id => @wms_parameter.id}).empty?
    @wms_parameter.destroy if is_not_used

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
    auth_on_param = BioCatalogue::Auth.allow_user_to_curate_thing?(current_user, @wms_parameter, :wms_method => WmsMethod.find(params[:wms_method_id]))

    unless auth_on_param || auth_on_meth
      error_to_back_or_home("You are not allowed to perform this action")
      return false
    end

    return true
  end


  # ========================================


  private

  def get_redirect_url()
    method_param_map = WmsMethodParameter.first(
        :conditions => {:wms_parameter_id => @wms_parameter.id,
                        :wms_method_id => params[:wms_method_id]})

    wms_method = WmsMethod.find(params[:wms_method_id])

    return wms_method_url(wms_method)
  end

  def destroy_method_param_map() # USES params[:wms_method_id] and @wms_parameter.id
    method_param_map = WmsMethodParameter.first(
        :conditions => {:wms_parameter_id => @wms_parameter.id,
                        :wms_method_id => params[:wms_method_id]})
    method_param_map.destroy
  end

  def find_wms_parameter
    @wms_parameter = WmsParameter.find(params[:id])
  end

  def find_wms_method
    @wms_method = WmsMethod.find(params[:wms_method_id])
  end

  def find_wms_methods
    @wms_methods = []

    @wms_parameter.wms_method_parameters.each { |map|
      method = WmsMethod.find(map.wms_method_id, :include => [ :wms_resource, :wms_service ])
      @wms_methods << method if method && !@wms_methods.include?(method)
    }

    @wms_methods.uniq!
  end

end
