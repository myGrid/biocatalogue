Factory.define :tag do |f|
  f.sequence(:label) { |n| "Tag #{n}" }
  f.sequence(:name) { |n| "Tag #{n}" }
end