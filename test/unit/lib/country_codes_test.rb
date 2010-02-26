# BioCatalogue: test/unit/lib/country_codes_test.rb
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

require 'test_helper'

class CountryCodesTest < ActionView::TestCase
  
  test "Loaded correctly" do
    assert_equal 246, CountryCodes.codes.length
  end
  
  test "Countries to codes" do
    assert_equal "TW", CountryCodes.code("Taiwan")
    assert_equal "TW", CountryCodes.code("TAIWAN, PROVINCE OF CHINA")
    assert_equal "GB", CountryCodes.code("United Kingdom")
  end
  
  test "Codes to countries" do
    assert_equal "TAIWAN", CountryCodes.country("TW")
    assert_equal "UNITED KINGDOM", CountryCodes.country("GB")
  end
  
end