class MenuTabBuilder < TabsOnRails::Tabs::Builder
  def open_tabs(options = {})
    @context.tag("ul", {:class => 'tabbernav tor'}, open = true)
  end

  def close_tabs(options = {})
    "</ul>".html_safe
  end

  def tab_for(tab, name, options, item_options = {})
    item_options[:class] = (current_tab?(tab) ? 'tabberactive' : '')
    @context.content_tag(:li, item_options) do
      @context.link_to(name, options)
    end
  end
end