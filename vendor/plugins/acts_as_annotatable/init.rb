# Include hook code here
require 'acts_as_annotatable'
ActiveRecord::Base.send(:include, BioCatalogue::Acts::Annotatable)
