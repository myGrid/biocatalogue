# BioCatalogue: script/biocatalogue/api/run_tests.rb
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# This runs all the tests for the API.
#
# NOTE (1): this is completely separate from the main test suite.
# NOTE (2): this expects a server to be running at http://localhost:3000 which it can access the API through.
#
#
# Dependencies:
# - libxml-ruby

require 'test/unit'
require File.join(File.dirname(__FILE__), 'tests', 'xml_schema_validations')

