# BioCatalogue: app/helpers/service_test_helper.rb
#
# Copyright (c) 2009-2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details.

module ServiceTestsHelper
  
  def sort_li_class_helper(param)
    result = 'class="sortup"' if params[:sort] == param
    result = 'class="sortdown"' if params[:sort] == param + "_reverse"
    return result
  end
  
  def sort_link_helper(text, param)
    key = param
    key += "_reverse" if params[:sort] == param
    options = {
      :url => {:action => 'index', :params => params.merge({:sort => key })}, #:page =>param[:page]
      :update => 'service_tests',
      :before => "Element.show('spinner')",
      :success => "Element.hide('spinner')"
      }
    html_options = {
      :title => "Sort by this field",
      :href => url_for(:action => 'index', :params => params.merge({:sort => key })) #:page => params[:page]
      }
    link_to_remote(text, options, html_options)
  end

end
