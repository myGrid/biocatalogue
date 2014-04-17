class ExternalCurationController < ApplicationController
  include CurationHelper
  def export
    services = xls_of_services
    rest_methods = xls_of_rest_methods
    soap_operations = xls_of_soap_operations
    respond_to do |format|
      format.xls { render :locals => {:services => services,
                                      :rest_methods => rest_methods,
                                      :soap_operations => soap_operations}
      }
    end
  end

  def new_import
    respond_to do |format|
      format.html
    end
  end

  def import
    file = params[:xls_file]

    begin
      spreadsheet = open_spreadsheet(file)
    rescue e
      flash[:notice] = "There was an error loading the document. Please read the instructions carefully."
      respond_to do |format|
        format.html {render :new_import}
      end
    end
    modified_lines = find_modified_rows(spreadsheet)
    respond_to do |format|
      format.html {render :locals => {:xls => modified_lines}}
    end
  end




  def find_modified_rows spreadsheet

    spreadsheet.each_with_pagename do |name, sheet|
      header = sheet.row(1)
        (2..sheet.last_row).each do |i|
          row = Hash[[header, sheet.row(i)].transpose]
          name.constantize.find_by_unique_code(row["Service ID"])
          service = Service.find_by_unique_code(row["Service ID"])

        end
    end

    return modified_lines
  end


  def open_spreadsheet(file)
    case File.extname(file.original_filename)
      when ".csv" then Roo::Csv.new(file.path, nil, :ignore)
      when ".xls" then Roo::Excel.new(file.path, nil, :ignore)
      when ".xlsx" then Roo::Excelx.new(file.path, nil, :ignore)
      else raise "Unknown file type: #{file.original_filename}"
    end
  end
end