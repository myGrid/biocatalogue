# BioCatalogue: lib/country_codes.rb
#
# Copyright (c) 2008-2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# Needs to take into account the fact that we are using a country select that has been modified.
# (ie: we are using: http://github.com/ihower/country_and_region_select)
module CountryCodes
  
  @@codes = Hash.new
  
# OLD:
#  File.open(File.join(RAILS_ROOT, 'data', 'countries.tab')).each do |record|
#    parts = record.split("\t")
#    @@codes[parts[0]] = parts[1].strip
#  end

  # NEW: uses the official ISO 3166 country codes XML file...
  raw = Hash.from_xml(IO.read(File.join(Rails.root, 'data', 'iso_3166-1_list_en.xml')))
  raw['iso_3166_1_list_en']['iso_3166_1_entry'].each do |e|
    @@codes[e['iso_3166_1_alpha_2_code_element']] = e['iso_3166_1_country_name']
  end
  
  #puts "countries = " + @@codes.to_s
  
  def self.country(code)
    return nil if code.blank?
    
    code = code.upcase
    code = "GB" if code == "UK"
    
    case code
      when "TW"
        return "TAIWAN" 
      when "BO"
        "BOLIVIA"
      when "MK"
        "MACEDONIA, REPUBLIC OF"
      when "MD"
        "MOLDOVA"
      when "MF"
        "SAINT MARTIN (FRENCH PART)"
      when "VE"
        "VENEZUELA"
      else
        return @@codes[code]
    end
  end
  
  def self.code(country)
    return nil if country.blank?
    
    c = nil
    
    country = "TAIWAN, PROVINCE OF CHINA" if country.downcase == "taiwan"
    country = "BOLIVIA, PLURINATIONAL STATE OF" if country.downcase == "bolivia"
    country = "MACEDONIA, THE FORMER YUGOSLAV REPUBLIC OF" if country.downcase == "macedonia, republic of"
    country = "MOLDOVA, REPUBLIC OF" if country.downcase == "moldova"
    country = "SAINT MARTIN" if country.downcase == "saint martin (french part)"
    country = "VENEZUELA, BOLIVARIAN REPUBLIC OF" if country.downcase == "venezuela"
    
    @@codes.each do |key, val|
      if country.mb_chars.downcase.strip == val.mb_chars.downcase
        c = key
        break
      end
    end
    
    return c
  end
  
  def self.valid_code?(code)
    @@codes.key?(code)
  end
  
  def self.codes
    @@codes
  end
  
end