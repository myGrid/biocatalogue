# BioCatalogue: lib/country_codes.rb
#
# Copyright (c) 2008-2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# Needs to take into account the fact that we are using a country select that has been modified.
# (ie: we are using: http://github.com/ihower/country_and_region_select)
module CountryCodes

  @@codes = Hash.new

  # Uses the official ISO 3166 country codes XML file, edited in accordance
  # with the note above.
  raw = Hash.from_xml(IO.read(File.join(Rails.root, 'data', 'iso_3166-1_list_en.xml')))
  raw['ISO_3166_1_List_en']['ISO_3166_1_Entry'].each do |e|
    code = e['ISO_3166_1_Alpha_2_Code_element']

    # Adjust some names (also titlecase breaks hyphenated and non-ascii names)
    entry = case code
              when "AX"
                "Aland Islands"
              when "MF"
                "Saint Martin (French part)"
              when "GW"
                "Guinea-Bissau"
              when "TL"
                "Timor-Leste"
              when "CI"
                "Cote d'Ivoire"
              when "BL"
                "Saint Barthelemy"
              when "LY"
                "Libya"
              when "SH"
                "Saint Helena, Ascension and Tristan da Cunha"
              when "VN"
                "Viet Nam"
              else
                e['ISO_3166_1_Country_name'].titlecase
            end

    ["And", "The", "Of"].each do |w|
      entry.gsub!(w, w.downcase)
    end

    @@codes[code] = entry
  end

  def self.country(code)
    return nil if code.blank?

    code = code.upcase
    code = "GB" if code == "UK"

    return @@codes[code]
  end

  def self.code(country)
    return nil if country.blank?

    c = nil

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
