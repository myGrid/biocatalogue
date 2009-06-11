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
    
    assert_equal [ "Prediction", "Structure Prediction", "Function Prediction" ],
                 @stub.process_values("Structure and Function Prediction")
                 
    assert_equal [ "TEST" ], @stub.process_values("TEST")
  end
  
  def test_underscored_and_spaced_versions_of
    assert_equal [ "my_value", "my value"  ], @stub.underscored_and_spaced_versions_of("my_value")
    
    assert_equal [ "my value", "my_value" ], @stub.underscored_and_spaced_versions_of("my value")
    
    assert_equal [ "value" ], @stub.underscored_and_spaced_versions_of("value")
    
    assert_equal [ "value" ], @stub.underscored_and_spaced_versions_of([ "value" ])
    
    assert_equal [ "value 1", "value_1", "value 2", "value_2", "value_3", "value 3" ], 
                 @stub.underscored_and_spaced_versions_of("value 1", [ "value 2", "value_3" ])
  end
  
  def test_to_list
    assert_equal "", @stub.to_list([])
    
    assert_equal "x", @stub.to_list([ "x" ])
    
    assert_equal "x,y,z", @stub.to_list([ "x", "y", "z" ])
  end
  
  def test_array_includes
    my_array = [ "Hello World", "hello", "GOOD evening" ]
    
    assert_equal false, @stub.array_includes?(my_array, "ihpihpi")
    
    assert_equal true, @stub.array_includes?(my_array, "hello")
    
    assert_equal true, @stub.array_includes?(my_array, "hello world")
    
    assert_equal true, @stub.array_includes?(my_array, "good evening")
  end
  
  def teardown
    
  end
  
end

Test::Unit::UI::Console::TestRunner.run(PseudoSynonymsTest)

