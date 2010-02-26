# BioCatalogue: script/biocatalogue/api/tests/test_config_helper.rb
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# Loads up a config.yml file and makes it available to other classes/modules that mix this in.

require 'yaml'

module TestConfigHelper
  
  def config
   @config ||= YAML.load(IO.read(File.join(File.dirname(__FILE__), 'config.yml')))
  end
  
end