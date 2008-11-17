# BioCatalogue: app/helpers/application_helper.rb
#
# Copyright (c) 2008, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details.

# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  
  def controller_visible_name(controller_name)
    controller_name.humanize.titleize
  end
  
  def flag_icon_from_country(country, text=country, style='')
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
      return flag_icon_from_country_code(code, text, style)
    else
      return ''
    end
  end
  
  def flag_icon_from_country_code(code, text=nil, style='margin-left: 0.8em;')
    code = "GB" if code.upcase == "UK"
    text = CountryCodes.country(code.upcase) if text.nil?
    return image_tag("flags/#{code.downcase}.png",
              :title => tooltip_title_attrib(text),
              :style => "vertical-align:middle; #{style}")
  end
  
  def tooltip_title_attrib(text, delay=200)
    return "header=[] body=[#{text}] cssheader=[boxoverTooltipHeader] cssbody=[boxoverTooltipBody] delay=[#{delay}]"
  end
  
  def geo_loc_to_text(geo_loc, style='', flag=true, flag_pos='right')
    return '' if geo_loc.nil?
    return '' if geo_loc.country_code.nil?
    
    text = ''
    
    city, country = BioCatalogue::Util.city_and_country_from_geoloc(geo_loc)
    
    unless city.blank? 
      text = text + "#{h(city)}, "
    end
    
    text = text + h(country) unless country.blank?
    
    country_code = h(geo_loc.country_code)
    
    if flag
      case flag_pos.downcase
        when 'right'
          text = text + flag_icon_from_country_code(country_code, nil, "margin-left: 0.8em;")
        when 'left'
          text = flag_icon_from_country_code(country_code, nil, "margin-right: 0.8em;") + text
        else
          text = text + flag_icon_from_country_code(country_code, nil, "margin-left: 0.8em;")
      end  
    end
    
    return text
  end
  
  def service_type_badges(service_types)
    html = ''
    
    unless service_types.blank?
      service_types.each do |s_type|
        html = html + content_tag(:span, s_type, :class => "service_type_badge", :style => "vertical-align: middle; margin-left: 0.8em;")
      end
    end
    
    return html
  end
  
  
  
end
