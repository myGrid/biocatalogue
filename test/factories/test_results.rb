# Generate Result Objects

Factory.define :test_result do |result|
  result.result 0
  result.action "action_that_was_executed"
  result.message {"message for test result"}
  result.association(:service_test)
end

Factory.define :successfull_test_result, :parent => :test_result do |result|
  result.result 0
end

Factory.define :failed_test_result, :parent => :test_result do |result|
  result.result 1
end

Factory.define :unchecked_test_result, :parent => :test_result do |result|
  result.result -1
end

