# Include hook code here
require 'is_testable'
ActiveRecord::Base.send(:include, BioCatalogue::Is::Testable)
