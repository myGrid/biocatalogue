# Generate ContentBlob Objects

Factory.define :content_blob do |cb|
  cb.sequence(:data) {|d| "content blob data#{d}"}
end