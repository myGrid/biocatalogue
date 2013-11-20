# BioCatalogue: app/controllers/curation_controller.rb
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details.

class CurationController < ApplicationController

  include RestServicesHelper #to access RestMethod template for CSV export


  before_filter :disable_action_for_api

  before_filter :login_or_oauth_required
  
  before_filter :authorise
  
  before_filter :parse_sort_params, :only => [:annotation_level]
  
  before_filter :find_services, :only => [:annotation_level]
  
  def show
    # show.html.erb
  end
  
  def copy_annotations
    if request.post?
      type = params[:type]
      from = nil
      to = nil
      
      unless type.blank?
        from = type.constantize.find_by_id(params[:from_id], :include => :annotations)
        to = type.constantize.find_by_id(params[:to_id])
      end
      
      if from.nil? or to.nil?
        flash[:error] = "Either the 'from' or 'to' item doesn't exist. So could not carry on with the copy."
      else
        anns = from.copy_annotations_to(to, current_user)
        flash[:notice] = "Successfully copied over #{anns.length} annotations."
        params[:from_id] = nil
        params[:to_id] = nil
      end
    end
    
    respond_to do |format|
      format.html # copy_annotations.html.erb
    end
  end

  def spreadsheet_export
    #All services in CSV format
    File.open('tmp/services.csv', 'w+'){|f|
      f.write(csv_of_services)}
    File.open('tmp/rest_methods.csv', 'w+'){|f|
      f.write(csv_of_rest_methods)}
    File.open('tmp/soap_operations.csv', 'w+'){|f|
      f.write(csv_of_soap_operations)}
    system("zip tmp/csv_export.zip tmp/services.csv tmp/rest_methods.csv tmp/soap_operations.csv")
    send_file 'tmp/csv_export.zip'
  end


  def csv_of_services
    services = Service.first(300)
    columns = ['Service ID','name','provider','location','submitter name','base url','annotations','category']
    return CSV.generate do |csv|
      csv << columns
      services.each {|service| csv << service.as_csv }
    end
  end

  def csv_of_soap_operations
    soap_operations = SoapOperation.first(300)
    columns =  ['Service ID','operation name','operation description','submitter','parameter order','annotations']
    return CSV.generate do |csv|
      csv << columns
      soap_operations.each { |soap_operation| csv << soap_operation.as_csv }
    end
  end

  def csv_of_rest_methods
    rest_methods = RestMethod.first(300)
    columns =  ['Service ID','endpoint name','template','method type','description','submitter','documentation url','annotations']
    return CSV.generate do |csv|
      csv << columns
      rest_methods.each{ |rest_method| csv << rest_method.as_csv }
    end
  end




  def copy_annotations_preview
    type = params[:type]
    from = nil
    to = nil
    
    unless type.blank?
      from = type.constantize.find_by_id(params[:from_id], :include => :annotations)
      to = type.constantize.find_by_id(params[:to_id])
    end
    
    unless from.nil? or to.nil?
      render :partial => "curation/copy_annotations/preview", :locals => { :type => type, :from => from, :to => to }
    else
      render :text => "<p class='error_text'>Either the 'from' or 'to' item doesn't exist</p>"
    end
  end
  
  def potential_duplicate_operations_within_service
    @operations = BioCatalogue::Curation::Reports.potential_duplicate_operations_within_service
    
    respond_to do |format|
      format.html # potential_duplicate_operations_within_service.html.erb
    end
  end
  
  def services_missing_annotations
    if params[:attribute_name].blank?
      @services = nil
    else
      @services = BioCatalogue::Curation::Reports.services_missing_annotations(params[:attribute_name])
    end
    
    respond_to do |format|
      format.html # services_missing_annotations.html.erb
    end
  end
  
  def annotation_level

    respond_to do |format|
      format.html # annotation_level.html.erb
    end
  end
    
  def providers_without_services
    @service_providers = BioCatalogue::Curation::Reports.providers_without_services

    respond_to do |format|
      format.html # providers_without_services.html.erb
    end
  end
  
  protected
  
  def parse_sort_params
    sort_by_allowed = [ "created", "ann_level" ]
    @sort_by = if params[:sort_by] && sort_by_allowed.include?(params[:sort_by].downcase)
      params[:sort_by].downcase
    else
      "created"
    end
    
    sort_order_allowed = [ "asc", "desc" ]
    @sort_order = if params[:sort_order] && sort_order_allowed.include?(params[:sort_order].downcase)
      params[:sort_order].downcase
    else
      "desc"
    end
  end
  
  def find_services
    
    conditions  = 'archived_at IS NULL'
    per_page        = 100

    case @sort_by
      when 'created'
        order_field = "created_at"
      when 'ann_level'
        order_field = 'annotation_level'
    end
    
    case @sort_order
      when 'asc'
        order_direction = 'ASC'
      when 'desc'
        order_direction = "DESC"
    end
    
    unless order_field.blank? or order_direction.nil?
      order = "services.#{order_field} #{order_direction}"
    end
    
       
    @services  = Service.paginate(:page => @page,
                                  :per_page => per_page, 
                                  :conditions => conditions,
                                  :order => order)
                              
    
  end

  def authorise    
    unless current_user.is_curator?
      flash[:error] = "You are not allowed to perform this action"
      redirect_to_back_or_home
    end

    return true
  end  

end