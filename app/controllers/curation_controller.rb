# BioCatalogue: app/controllers/curation_controller.rb
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details.

class CurationController < ApplicationController


  include CurationHelper

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

  def download_csv_page
    respond_to do |format|
      format.html
    end
  end

  def download_latest_csv
    if !latest_csv_export.nil?
      send_file latest_csv_export
    else
      flash[:notice] = "There are currently no CSV exports to download. Please run 'Export Services as CSV' to create a new one."
      redirect_to :back
    end
  end

  def spreadsheet_export
    export_folder = Rails.root.join('data',"#{Rails.env}-csv-exports")
    unless File.directory?(export_folder)
      Dir.mkdir(export_folder)
    end

    require 'zip'
    time = Time.now.strftime("%Y%m%d%H%M")
    zip_file = "#{export_folder}/csv_export-#{time}.zip"
    tables = %w{services rest_methods soap_operations}
    files = []
    tables.each{|table_name| files << "tmp/#{table_name}.csv"}

    files.each do |file|
      File.delete(file) if File.exist?(file)
    end

    File.open('tmp/services.csv', 'w+'){|f|
      f.write(csv_of_services)}
    File.open('tmp/rest_methods.csv', 'w+'){|f|
      f.write(csv_of_rest_methods)}
    File.open('tmp/soap_operations.csv', 'w+'){|f|
      f.write(csv_of_soap_operations)}
    zip_files(zip_file, tables)
    #system("zip -j data/csv-exports/csv_export-#{time}.zip tmp/services.csv tmp/rest_methods.csv tmp/soap_operations.csv")
    if File.exist?(zip_file)
      send_file zip_file
    else
      download_latest_csv
    end
  end

  def zip_files zip_file, tables

    if !File.exists?(zip_file)
      Zip::File.open(zip_file, Zip::File::CREATE) do |zf|
        tables.each do |table|
          file_path = "tmp/#{table}.csv"
          zf.add("#{table}.csv", file_path)
        end
      end
    else
      flash.now[:alert] = "Cannot export more than once a minute. Here is the last CSV export."
    end
  end

  def csv_of_services
    services = Service.all
    columns = ['Service ID','name','provider','location','submitter name',
               'base url','documentation url','description','licence','costs',
               'usage conditions','contact','publications','citations','annotations',
               'categories']
    return CSV.generate do |csv|
      csv << columns
      services.each {|service| csv << service.as_csv unless service.nil?}
    end
  end

  def csv_of_soap_operations
    soap_operations = SoapOperation.all
    columns =  ['Service ID','operation name','operation description','submitter',
                'parameter order','annotations', 'port name', 'port protocol', 'port location', 'port style']
    return CSV.generate do |csv|
      csv << columns
      soap_operations.each { |soap_operation| csv << soap_operation.as_csv unless soap_operation.nil?}
    end
  end

  def csv_of_rest_methods
    rest_methods = RestMethod.all
    columns =  ['Service ID','endpoint name','method type','template','description',
                'submitter','documentation url','example endpoints','annotations']
    return CSV.generate do |csv|
      csv << columns
      rest_methods.each{ |rest_method| csv << rest_method.as_csv unless rest_method.nil?}
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