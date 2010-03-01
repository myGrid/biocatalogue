# BioCatalogue: script/biocatalogue/api/tests/test_helper.rb
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

require File.join(File.dirname(__FILE__), 'test_config_helper')

require 'rubygems'

module TestHelper

  include TestConfigHelper
  
  HTTP_USER_AGENT = "BioCatalogue test bot; Ruby/#{RUBY_VERSION}".freeze
  
  def make_url(path)
    URI.join(config["server"], path)
  end
  
end
