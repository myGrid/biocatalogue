# Generate Service Objects

Factory.define :service do |service|
  service.sequence(:name) { |n| "service_#{n}" }
  service.submitter {|u| Factory(:user)}
end

Factory.define :service_with_test, :parent => :service do | service|
  service.after_create {|s| Factory(:service_test, :service => s)}
end