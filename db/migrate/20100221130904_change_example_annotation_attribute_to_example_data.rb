class ChangeExampleAnnotationAttributeToExampleData < ActiveRecord::Migration
  def self.up
    attrib = AnnotationAttribute.find_by_name('example')
    if attrib
      attrib.name = "example_data"
      attrib.save!
    end
  end

  def self.down
    attrib = AnnotationAttribute.find_by_name('example_data')
    if attrib
      attrib.name = "example"
      attrib.save!
    end
  end
end
