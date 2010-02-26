# Generate Annotation objects

Factory.define :annotation do |f|
  f.attribute_name { Annotation.attribute_name }
  f.sequence(:value) { |n| "value #{n}" }
  f.association :annotatable, :factory => :service
  f.association :source, :factory => :user
end