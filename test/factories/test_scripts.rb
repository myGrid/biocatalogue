
# Generate TestScript objects

Factory.define :test_script do |ts|
  ts.name "name"
  ts.exec_name "exec_name"
  ts.description "description"
  ts.filename "filename"
  ts.content_type "application/xml"
  ts.prog_language "soapui"
  ts.user {|a| a.association(:user)}
  ts.content_blob {|a| a.association(:content_blob)}
  
end

Factory.define :test_script_with_user, :parent => :test_script do |script|
  script.association(:user)
end

Factory.define :test_script_with_results, :parent => :test_script do |script|
  script.after_create {|s| Factory(:service_test_with_result, :test => s)}
end