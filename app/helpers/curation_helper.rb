# BioCatalogue: app/helpers/curation_helper.rb
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details.

include ServicesHelper

module CurationHelper

  def sort_li_class_helper(param, order)
    result = 'class="sortup"' if (params[:sort_by] == param && params[:sort_order] == order)
    result = 'class="sortdown"' if (params[:sort_by] == param && params[:sort_order] == reverse_order(order))
    return result
  end


  def elixir_service_check
    # All the services that have a special 'Elixir Description'
    services = []
    elixir_descriptions = Annotation.with_attribute_name('elixir_description')
    elixir_descriptions.each do |ed|
      services << ed.annotatable
    end
    services.uniq!

    elixir_services = []
    # For each service
    # Map to edam topic/operation
    # Extract homepage link
    # Extract contact URL/email
    # Throw it away if it doesn't have any of the above
    services.each do |service|
      g_service = service.service
      categories = g_service.annotations.select { |ann| ann.value_type == "Category" }.collect { |cat| cat.value.name }

      # Map the Services Categories to EDAM Topics and EDAM Operations
      edam_topics = []
      categories.each { |x| edam_topics << [x, map_categories_to_edam_topics(x)] }
      edam_topics.reject! { |c| c[1].empty? }
      edam_topics.uniq!
      operations = []
      categories.each { |x| operations << [x, map_categories_to_edam_operations(x)] }
      operations.reject! { |c| c[1].empty? }
      operations.uniq!

      # For the homepage we'll be using the documentation URL
      doc_link = (service.has_documentation_url? ? service.preferred_documentation_url : '')
      homepage = URI::extract(doc_link)
      # URI::extract things 'SAWSDL: ' is a URI so we need to check for http or www too.
      homepage.select! { |string| string.starts_with?('http') || string.starts_with?('www.') }
      homepage = homepage.first unless homepage.nil?

      # Contact is a free text annotation and we need to extract JUST an email address or URL from it.
      # This takes the first. Splits by whitespace. Check each item for valid address.
      # Could make it loop over all contact annotations if the first one has neither email or url
      contact = g_service.list_of("contact").first
      contact_url = nil
      contact_email = nil
      unless contact.nil?
        contacts = contact.split(" ")
        contacts.select! { |element| ValidatesEmailFormatOf::validate_email_format(element) == nil }
        if !contacts.empty?
          contact_email = contacts.first
        elsif contact =~ URI::regexp
          contact_url = URI::extract(contact)
          contact_url.select! { |string| string.starts_with?('http') || string.starts_with?('www.') }
          contact_url = contact_url.first unless contact_url.nil?
        end
      end
      valid = !operations.empty? &&
          !edam_topics.empty? &&
              !g_service.preferred_description.nil? &&
                  !g_service.archived? &&
                      !(contact_url.nil? && contact_email.nil?) &&
                          !homepage.nil?

      elixir_services << {:service => service,
                          :g_service => g_service,
                          :valid => valid,
                          :homepage => homepage,
                          :contact_url => contact_url,
                          :contact_email => contact_email,
                          :archived => g_service.archived?,
                          :edam_topics => edam_topics,
                          :edam_operations => operations}
    end
    return elixir_services
  end

  def latest_csv_export
    report_folder = Rails.root.join('data', "#{Rails.env}_reports")
    export_folder = Rails.root.join('data', "#{Rails.env}_reports", "csv_exports")
    unless Dir.exists?(report_folder)
      Dir.mkdir(report_folder)
    end
    unless File.directory?(export_folder)
      Dir.mkdir(export_folder)
    end
    files = Dir.entries(export_folder)
    files = files.select { |file| file.match("csv_export-") }
    latest_file = files.sort.last
    if !latest_file.nil? && latest_file != ""
      return "#{export_folder}/#{latest_file}"
    else
      return nil
    end
  end

  def time_of_export file_name
    file_name.gsub!(/\D+/, '')
    format_time(file_name.to_time)
  end

  def format_time(time)
    time.strftime("%e %b %Y %H:%M:%S %Z") || 'not available'
  end

  def spreadsheet_export
    report_folder = Rails.root.join('data', "#{Rails.env}_reports")
    export_folder = Rails.root.join('data', "#{Rails.env}_reports", "csv_exports")
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
    tables.each { |table_name| files << "tmp/#{table_name}.csv" }

    files.each do |file|
      File.delete(file) if File.exist?(file)
    end

    File.open('tmp/services.csv', 'w+') { |f|
      f.write(csv_of_services) }
    File.open('tmp/rest_methods.csv', 'w+') { |f|
      f.write(csv_of_rest_methods) }
    File.open('tmp/soap_operations.csv', 'w+') { |f|
      f.write(csv_of_soap_operations) }
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
    columns = ['Service ID', 'name', 'provider', 'location', 'submitter name',
               'base url', 'documentation url', 'description', 'licence', 'costs',
               'usage conditions', 'contact', 'publications', 'citations', 'annotations',
               'categories']
    return CSV.generate do |csv|
      csv << columns
      services.each { |service| csv << service.as_csv unless service.nil? }
    end
  end

  def csv_of_soap_operations
    soap_operations = SoapOperation.all
    columns = ['Service ID', 'operation name', 'operation description', 'submitter',
               'parameter order', 'annotations', 'port name', 'port protocol', 'port location', 'port style']
    return CSV.generate do |csv|
      csv << columns
      soap_operations.each { |soap_operation| csv << soap_operation.as_csv unless soap_operation.nil? }
    end
  end

  def csv_of_rest_methods
    rest_methods = RestMethod.all
    columns = ['Service ID', 'endpoint name', 'method type', 'template', 'description',
               'submitter', 'documentation url', 'example endpoints', 'annotations']
    return CSV.generate do |csv|
      csv << columns
      rest_methods.each { |rest_method| csv << rest_method.as_csv unless rest_method.nil? }
    end
  end


  def curation_sort_link_helper(text, param, order)
    key = param
    order = order
    order = reverse_order(params[:sort_order]) if params[:sort_by] == param
    params.delete(:page) # reset page
    options = {
        :url => {:action => 'annotation_level', :params => params.merge({:sort_by => key, :sort_order => order})}, #:page =>param[:page]
        :update => 'annotation_level',
        :before => "Element.show('spinner')",
        :success => "Element.hide('spinner')"
    }
    html_options = {
        :title => "Sort by this field",
        :href => url_for(:action => 'annotation_level', :params => params.merge({:sort_by => key, :sort_order => order})) #:page => params[:page]
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
