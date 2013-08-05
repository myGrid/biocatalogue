# Generate ServiceTest Objects

Factory.define :service_test do |stest|
  #stest.test_type  "TestScript"
  #stest.sequence(:test_id) { |x| x }
  stest.association(:service)
  stest.test {|t| t.association(:test_script)}
end

#Factory.define :script_service_test, :parent => :service_test do |service_test|
# service_test.test {|t| t.association(:test_script)}
#end

Factory.define :script_service_test_with_result, :parent => :service_test do |service_test|
 service_test.after_create {|st| Factory(:test_result, :service_test => st) }
end
