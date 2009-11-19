class ChangeNameAnnotationAttributeToAlternativeName < ActiveRecord::Migration
  def self.up
    a = AnnotationAttribute.find_by_name("name")
    unless a.nil?
      a.name = "alternative_name"
      a.save!
    end
  end

  def self.down
    a = AnnotationAttribute.find_by_name("alternative_name")
    unless a.nil?
      a.name = "name"
      a.save!
    end
  end
end
