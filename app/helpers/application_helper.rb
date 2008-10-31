# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  
  def controller_visible_name(controller_name)
    controller_name.humanize.titleize
  end
  
  def flag_icon(country, text=country, style='')
    return '' if country.blank?
    
    code = ''
    
    if country.downcase == "great britain"
      code = "gb"
    elsif ["england", "wales", "scotland"].include?(country.downcase)
      code = country
    elsif country.length > 2
      code = CountryCodes.code(country)
    else
      code = country if CountryCodes.valid_code?(country)
    end
    
    #puts "code = " + code
    
    unless code.blank?
      return image_tag("flags/#{code.downcase}.png",
              :title => "header=[] body=[<b>Location: </b>#{text}] cssheader=[boxoverTooltipHeader] cssbody=[boxoverTooltipBody] delay=[200]",
              :style => "vertical-align:middle; #{style}")
    else
      return ''
    end
  end
end
