# BioCatalogue: app/helpers/service_test_helper.rb
#
# Copyright (c) 2009-2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details.

module ServiceTestsHelper
  
  def sort_li_class_helper(param, order)
    result = 'class="sortup"' if (params[:sort_by] == param && params[:sort_order] == order)
    result = 'class="sortdown"' if (params[:sort_by] == param && params[:sort_order] == reverse_order(order))  
    return result
  end
  
  def sort_link_helper(text, param, order)
    key   = param
    order = order
    order = reverse_order(params[:sort_order]) if params[:sort_by] == param
    options = {
      :url => {:action => 'index', :params => params.merge({:sort_by => key , :sort_order => order})}, #:page =>param[:page]
      :update => 'service_tests',
      :before => "Element.show('spinner')",
      :success => "Element.hide('spinner')"
      }
    html_options = {
      :title => "Sort by this field",
      :href => url_for(:action => 'index', :params => params.merge({:sort_by => key, :sort_order => order })) #:page => params[:page]
      }
    link_to_remote(text, options, html_options)
  end
  
  def reverse_order(order)
    orders ={'asc' => 'desc', 'desc' => 'asc'}
    return orders[order]
  end
  
end
