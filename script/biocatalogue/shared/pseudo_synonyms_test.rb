require File.join(File.dirname(__FILE__), 'pseudo_synonyms')

require 'test/unit'
require 'test/unit/ui/console/testrunner'

class PseudoSynonymsStub
  include PseudoSynonyms
end

class PseudoSynonymsTest < Test::Unit::TestCase

  def setup
    @stub = PseudoSynonymsStub.new
  end
    
  def test_process_values
    assert_equal [ "x", "Prediction", "Structure Prediction", "Function Prediction", "y" , "z" ], 
                 @stub.process_values("x", "Structure and Function Prediction", [ "y", "z" ]) 
  end
  
  def test_process_value
    assert_equal [ "Prediction", "Structure Prediction", "Function Prediction" ],
                 @stub.process_value("Structure and Function Prediction")
                 
    assert_equal [ "TEST" ], @stub.process_value("TEST")
  end
  
  def test_underscored_and_spaced_versions_of
    assert_equal [ "my_value", "my value"  ], @stub.underscored_and_spaced_versions_of("my_value")
    
    assert_equal [ "my value", "my_value" ], @stub.underscored_and_spaced_versions_of("my value")
    
    assert_equal [ "value" ], @stub.underscored_and_spaced_versions_of("value")
  end
  
  def test_to_list
    assert_equal "", @stub.to_list([])
    
    assert_equal "x", @stub.to_list([ "x" ])
    
    assert_equal "x,y,z", @stub.to_list([ "x", "y", "z" ])
  end
  
  def teardown
    
  end
  
end

Test::Unit::UI::Console::TestRunner.run(PseudoSynonymsTest)

