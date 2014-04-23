class ExternalCurationController < ApplicationController

  include CurationHelper


  def export
    services = xls_of_services
    rest_methods = xls_of_rest_methods
    soap_operations = xls_of_soap_operations
    respond_to do |format|
      format.xls { render :locals => {:headers => headers,
                                      :services => services,
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
      raise "There was a problem loading the spreadsheet. Please ensure you have read the instructions" if spreadsheet.nil?
=begin
      modifications = Rails.cache.read(file.original_filename.to_s)
      if modifications.nil?
=end
      modifications = find_modified_rows(spreadsheet)
=begin
        Rails.cache.write(file.original_filename.to_s, modifications)
      end
=end

      respond_to do |format|
        format.html {render :locals => {:xls => modifications}}
      end
    rescue Exception => e
      flash[:notice] = "There was an error loading the document"
      @error = "#{e.backtrace.join("\n")}"
      respond_to do |format|
        format.html {render :new_import}
      end
    end
  end

  private
  def find_modified_rows spreadsheet
    modifications = {}
    unless spreadsheet.nil?
      spreadsheet.each_with_pagename do |sheet_name, sheet|
        header = sheet.row(1)
        if check_headers_match(header, sheet_name)
          modifications[sheet_name] = []
          (2..sheet.last_row).each do |i|
            excel_record_array = sheet.row(i)
            db_record_array = get_database_record(sheet_name, excel_record_array)
            modifications[sheet_name] << changes_to_record(sheet_name, header, excel_record_array, db_record_array)
          end
        else
          raise 'At least one of the column headings in the imported document do not match up to the original export headers'
        end
      end
    end
    return modifications
  end

  def get_database_record(record_type, record)
    record_class = record_type.singularize.constantize
    return record_class.find(record.first)
  end

  def changes_to_record(record_type, header, xls_record, db_record)
    changes = []
    db_record_array = db_record.as_csv
    if db_record_array != xls_record
      excel_record_hash = Hash[[header, xls_record].transpose]
      db_record_hash = Hash[[header, db_record_array].transpose]
      excel_record_hash.each do |field, value|
        if db_record_hash[field] != value
          changes << {:old => db_record_hash[field], :new => value, :field => field}
        end
      end
      return {:object => db_record, :changes => changes}
    else
      return nil
    end
  end


  # Check the column titles match up with the original ones
  def check_headers_match new_header, sheet_name
    return new_header == get_original_header(sheet_name)
  end

  def get_original_header sheet_name
    case sheet_name
      when 'RestMethods'
        return REST_METHOD_COLUMNS
      when 'SoapOperations'
        return SOAP_OPERATION_COLUMNS
      when 'Services'
        return SERVICE_COLUMNS
      else
        raise 'Could not match headengs to new headings'
    end
  end


  def headers
    return {:service_columns => SERVICE_COLUMNS,
            :soap_operation_columns => SOAP_OPERATION_COLUMNS,
            :rest_method_columns => REST_METHOD_COLUMNS}
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