class ChangeNameAnnotationAttributeToAlternativeName < ActiveRecord::Migration
  def self.up
    a = AnnotationAttribute.find_by_name("name")
    a.name = "alternative_name"
    a.save!
  end

  def self.down
    a = AnnotationAttribute.find_by_name("alternative_name")
    a.name = "name"
    a.save!
  end
end
