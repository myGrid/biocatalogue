# BioCatalogue: test/unit/lib/bio_catalogue/util_test.rb
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

require 'test_helper'

class UtilTest < ActionView::TestCase
  
  def setup
  end

  test "Test uniq_strings_case_insensitive" do
    
    a = [ "a", "b", "a", "c", "a" ]
    b = [ "a", "B", "c", "b", "A", "a", "d" ]
    c = [ "a", "b", "c" ]
    
    x = BioCatalogue::Util.uniq_strings_case_insensitive(a)
    y = BioCatalogue::Util.uniq_strings_case_insensitive(b)
    z = BioCatalogue::Util.uniq_strings_case_insensitive(c)
    
    assert_equal 3, x.length
    assert_equal 4, y.length
    assert_equal 3, z.length
    
    # TODO: add cases with non strings in them and test for error handling / fault tolerance
    
  end
  
end
