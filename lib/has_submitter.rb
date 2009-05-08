# BioCatalogue: app/lib/has_submitter.rb
#
# Copyright (c) 2009, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

module BioCatalogue
  module Has #:nodoc:
    module Submitter #:nodoc:
      def self.included(mod)
        mod.extend(ClassMethods)
      end
      
      module ClassMethods
        def has_submitter
          belongs_to :submitter,
                     :polymorphic => true

          class_eval do
            extend BioCatalogue::Has::Submitter::SingletonMethods
          end
          include BioCatalogue::Has::Submitter::InstanceMethods
        end
      end
      
      module SingletonMethods
        
      end
      
      module InstanceMethods
        def submitter_name
          %w{ display_name name title }.each do |w|
            return eval("submitter.#{w}") if submitter.respond_to?(w)
          end
          return "#{submitter.class.name}_#{id}"
        end 
      end
    end
  end
end

ActiveRecord::Base.send(:include, BioCatalogue::Has::Submitter)