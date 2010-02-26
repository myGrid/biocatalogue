# BioCatalogue: test/integration/flags_and_country_codes_test.rb
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

require 'test_helper'

class FlagsAndCountryCodesTest < ActionView::TestCase
  
  test "Check countries list to codes list match and vice versa" do
    assert_equal CountryCodes.codes.length, ActionView::Helpers::FormOptionsHelper::COUNTRIES.length
    
    ActionView::Helpers::FormOptionsHelper::COUNTRIES.each do |c|
      assert !CountryCodes.code(c).blank?, "Country '#{c}' does not have a corresponding ISO3166 code"
    end
    
    CountryCodes.codes.keys.each do |c|
      v = CountryCodes.country(c)
      assert !v.blank?, "Code '#{c}' does not have a corresponding country name"
      unless v.blank?
        upcased_countries = ActionView::Helpers::FormOptionsHelper::COUNTRIES.map{ |x| x.mb_chars.upcase.to_s }
        assert upcased_countries.include?(v.mb_chars.upcase.to_s), 
          "The country name returned for the code '#{c}' does not exist in the COUNTRIES list of the countries select plugin"
      end
    end
  end
  
  test "Check flag icons are available" do 
    CountryCodes.codes.keys.each do |c|
      unless ApplicationHelper::EXCLUDED_FLAG_CODES.include? c
        path = File.join(Rails.root, 'public', 'images', 'flags', "#{c.downcase}.png")
        assert File.exist?(path), "Flag icon for code '#{c}' does not exist at path: #{path}"
      end
    end
  end
  
end