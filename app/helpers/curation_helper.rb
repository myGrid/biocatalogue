# BioCatalogue: app/helpers/curation_helper.rb
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details.

module CurationHelper
  
 def sort_li_class_helper(param, order)
    result = 'class="sortup"' if (params[:sort_by] == param && params[:sort_order] == order)
    result = 'class="sortdown"' if (params[:sort_by] == param && params[:sort_order] == reverse_order(order))  
    return result
 end

 def latest_csv_export
   report_folder = Rails.root.join('data',"#{Rails.env}_reports")
   export_folder = Rails.root.join('data',"#{Rails.env}_reports", "csv_exports")
   unless Dir.exists?(report_folder)
     Dir.mkdir(report_folder)
   end
   unless File.directory?(export_folder)
     Dir.mkdir(export_folder)
   end
   files = Dir.entries(export_folder)
   files = files.select{|file| file.match("csv_export-") }
   latest_file = files.sort.last
   if !latest_file.nil? && latest_file != ""
     return "#{export_folder}/#{latest_file}"
   else
     return nil
   end
 end

 def time_of_export file_name
   file_name.gsub!(/\D+/, '')
   file_name.to_time.strftime("%e %b %Y %H:%M:%S %Z")
 end


 def spreadsheet_export
   report_folder = Rails.root.join('data',"#{Rails.env}_reports")
   export_folder = Rails.root.join('data',"#{Rails.env}_reports", "csv_exports")
   unless Dir.exists?(report_folder)
     Dir.mkdir(report_folder)
   end
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


 def curation_sort_link_helper(text, param, order)
    key   = param
    order = order
    order = reverse_order(params[:sort_order]) if params[:sort_by] == param
    params.delete(:page) # reset page
    options = {
      :url => {:action => 'annotation_level', :params => params.merge({:sort_by => key , :sort_order => order})}, #:page =>param[:page]
      :update => 'annotation_level',
      :before => "Element.show('spinner')",
      :success => "Element.hide('spinner')"
      }
    html_options = {
      :title => "Sort by this field",
      :href => url_for(:action => 'annotation_level', :params => params.merge({:sort_by => key, :sort_order => order })) #:page => params[:page]
      }
    link_to_with_callbacks(text, options, html_options.merge(:remote => true))
  end
  
  def reverse_order(order)
    orders ={'asc' => 'desc', 'desc' => 'asc'}
    return orders[order]
  end
  
  # convert to an html nested list
  def from_list_to_html(list, depth_to_traverse=1000, start_depth=0)
    depth = start_depth
    if list.is_a?(Array) && !list.empty?
      str =''
      str << '<ul>'
      depth += 1
      list.each do |value|
        unless depth > depth_to_traverse
          str << "<li> #{value} </li> "
          if value.is_a?(Array) 
            str << from_hash_to_html(value, depth_to_traverse, depth)
          end
        end
      end
      str << '</ul> '
      return str.html_safe
    end
    return ''
  end
end
