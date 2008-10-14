# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  
  def controller_visible_name(controller_name)
    controller_name.humanize.titleize
  end
  
end
