# BioCatalogue: lib/acts_as_archived.rb
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

module BioCatalogue
  module ActsAsArchived #:nodoc:
    def self.included(mod)
      mod.extend(ClassMethods)
    end
    
    module ClassMethods
      def acts_as_archived
        
        __send__ :include, InstanceMethods
        
        named_scope :archived, lambda { 
          { :conditions => "#{self.table_name}.archived_at IS NOT NULL" }
        }
        
        named_scope :not_archived, lambda {
          { :conditions => "#{self.table_name}.archived_at IS NULL" }
        }
        
      end
    end
    
    module InstanceMethods
      
      def archive!
        self.update_attributes({ :archived_at => Time.now, :updated_at => Time.now })
      end
      
      def unarchive!
        self.update_attributes({ :archived_at => nil, :updated_at => Time.now })
      end
    
      def archived?
        !self.archived_at.nil?
      end
      
    end
  end
end

ActiveRecord::Base.send(:include, BioCatalogue::ActsAsArchived)
