# BioCatalogue: test/unit/soap_service_port_test.rb
#
# Copyright (c) 2009, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details.

require 'test_helper'

class SoapServicePortTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "the truth" do
    assert true
  end
  
  # must have a name
  test "must have a name" do
    p = SoapServicePort.new
    assert !p.save, " Port was saved without a name"
  end
end
