module Annotations
  module Util
    
    # Overriding this from the Annotations plugin so that 
    # we can have our own custom logic to migrate the 
    # Annotations data to the v3 schema.
    def self.migrate_annotations_to_v3
      BioCatalogue::Util::say "Running custom logic to migrate the Annotations data to the v3 schema..."
      
      Annotation.record_timestamps = false
      
      Annotation.all.each do |ann|
        begin
          ann.transaction do
            # Take this opportunity to do some cleanup of the data
            if ann.annotatable.nil? or ann.source.nil? 
              ann.destroy
            else
              case ann.attribute_name.downcase
                when 'tag', *Temp::MYGRID_ONTOLOGY_ATTRIBUTES
                  Temp.migrate_tag(ann)
                when 'category'
                  Temp.migrate_category(ann)
                when 'rating.documentation'
                  ann.destroy
                else
                  Temp.migrate_text(ann)
              end
            end
          end
        rescue Exception => ex
          BioCatalogue::Util::yell "FAILED to migrate annotation with ID #{ann.id}. Error message: #{ex.message}"
          
          if ex.message == "Validation failed: This annotation already exists and is not allowed to be created again."
            puts "Deleting existing annotation with ID #{ann.id}"
            ann.destroy 
          end
        end
      end
      
      Annotation.record_timestamps = true
    end
    
    
    module Temp
      MYGRID_ONTOLOGY_ATTRIBUTES = [
        "<http://www.mygrid.org.uk/mygrid-moby-service#hasParameterType>".downcase,
        "<http://www.mygrid.org.uk/mygrid-moby-service#inNamespaces>".downcase,
        "<http://www.mygrid.org.uk/mygrid-moby-service#objectType>".downcase,
        "<http://www.mygrid.org.uk/mygrid-moby-service#performsTask>".downcase,
        "<http://www.mygrid.org.uk/mygrid-moby-service#usesMethod>".downcase,
        "<http://www.mygrid.org.uk/mygrid-moby-service#usesResource>".downcase
      ].freeze
      
      TAG_NAMESPACES = { "http://www.mygrid.org.uk/ontology" => "mygrid-domain-ontology", 
                         "http://www.mygrid.org.uk/mygrid-moby-service" => "mygrid-service-ontology" }.freeze
      
      def self.migrate_tag(ann)
        namespace, term_keyword = self.split_ontology_term_uri(ann.old_value)
        
        tag = Tag.find_or_create_by_label_and_name(term_keyword, ann.old_value)
        
        # Set the right timestamps
        tag.created_at = ann.created_at if (tag.created_at.blank? || ann.created_at < tag.created_at)
        tag.updated_at = ann.created_at if (tag.updated_at.blank? || ann.created_at < tag.created_at)
        tag.save!
        
        ann.value = tag
        ann.old_value = nil
        ann.save!
        
        self.remove_older_versions(ann)
      end
      
      def self.migrate_category(ann)
        cat = Category.find(ann.old_value)
        
        ann.value = cat
        ann.old_value = nil
        ann.save!
        
        self.remove_older_versions(ann)
      end
      
      def self.migrate_text(ann)
        val = TextValue.new
        
        # Handle versions
        #
        # NOTE: This will take a naive approach of assuming that
        # only the 'old_value' field has been changed in the annotations
        # table over time, nothing else!
        
        # Build up the TextValue from the versions
        ann.versions.each do |v|
          val.text = v.old_value
          val.version_creator_id = v.version_creator_id
          val.created_at = v.created_at unless val.created_at
          val.updated_at = v.updated_at
          val.save!
        end
        
        # Be defensive!
        val.text = ann.old_value if val.text.blank?
        val.created_at = ann.created_at if val.created_at.blank?
        val.updated_at = ann.updated_at if val.updated_at.blank?
        
        # Assign new TextValue to Annotation
        ann.value = val
        
        if TextValue.has_duplicate_annotation?(ann)
          # Delete the existing annotation
          ann.destroy
        else
          # Otherwise, save it with the new value
          ann.old_value = nil
          ann.save!
          
          self.remove_older_versions(ann)
        end
      end
      
      def self.remove_older_versions(ann)
        # Only keep the last version,
        # deleting others, and resetting version
        # numbers, and setting timestamps accordingly.
        ann.versions(true).each do |version|
          if version == ann.versions[-1]
            # The one we want to keep
            version.version = 1
            version.version_creator_id = ann.version_creator_id
            version.created_at = ann.created_at
            version.updated_at = ann.created_at
            version.save!
          else
            # Delete!
            version.destroy
          end
        end
        ann.version = 1
        ann.save!    # This shouldn't result in a new version
      end
      
      def self.is_ontology_term_uri?(tag_name)
        return tag_name.starts_with?("<") && tag_name.ends_with?(">") && tag_name.include?("#") 
      end
      
      def self.split_ontology_term_uri(tag_name)
        namespace = ""
        term_keyword = ""
        if self.is_ontology_term_uri?(tag_name)
          base_uri, term_keyword = tag_name.gsub(/[<>]/, "").split("#")
          if TAG_NAMESPACES.has_key?(base_uri.downcase)
            namespace = TAG_NAMESPACES[base_uri]
          else
            term_keyword = tag_name
          end
        else
          term_keyword = tag_name
        end
        return [ namespace, term_keyword ]
      end
    end
    
  end
end
