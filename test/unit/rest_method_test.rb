require 'test_helper'

class RestMethodTest < ActiveSupport::TestCase
  def test_create_invalid
    meth = RestMethod.new().save
    assert !meth
  end

  def test_check_duplicate
    rest = create_rest_service(:endpoints => "/people?name={doe}")
    
    assert_not_nil RestMethod.check_duplicate(rest.rest_resources[0], "GET")
    assert_nil RestMethod.check_duplicate(rest.rest_resources[0], "PUT")
    
    rest.service.destroy
  end
  
  def test_submitter
    user = Factory.create(:user)
    rest_service = create_rest_service(:endpoints => "/resource.xml", :submitter => user)
    
    assert_equal rest_service.rest_resources[0].rest_methods[0].submitter, user # same submitter
    
    rest_service.service.destroy
  end

  def test_check_endpoint_name_exists
    rest = create_rest_service(:endpoints => "/{id}\n put /{id} \n post /{db} \n delete /{db}/{id}")
    
    rest.rest_resources[0].rest_methods[0].endpoint_name = "some name"
    rest.rest_resources[0].rest_methods[0].save!
    
    assert rest.rest_resources[2].rest_methods[0].check_endpoint_name_exists("some name")
    assert !rest.rest_resources[2].rest_methods[0].check_endpoint_name_exists("some other name")

    rest.service.destroy
  end
  
  def test_create_endpoint_with_no_params
    rest = create_rest_service(:endpoints => "/search")
    assert rest.rest_resources[0].rest_methods[0].request_parameters.empty?

    rest.service.destroy
  end
  
  def test_create_endpoint_with_query_params
    rest = create_rest_service(:endpoints => "/search?q={term}&style=raw")
    params = rest.rest_resources[0].rest_methods[0].request_parameters.select{ |p| p.param_style == "query" }
    
    assert_equal 1, params.size
    assert_equal "q", params[0].name
    
    assert_equal "/search?style=raw", rest.rest_resources[0].path

    rest.service.destroy
  end

  def test_create_endpoint_with_template_params
    rest = create_rest_service(:endpoints => "/{db}/download/{id}.{format}")
    params = rest.rest_resources[0].rest_methods[0].request_parameters.select{ |p| p.param_style == "template" }
    
    assert_equal 3, params.size
    params.each { |p| assert %w{ db id format }.include?(p.name) }
    
    assert_equal "/{db}/download/{id}.{format}", rest.rest_resources[0].path

    rest.service.destroy
  end
  
  def test_create_endpoint_with_template_and_query_params
    rest = create_rest_service(:endpoints => "/{api-v}/search.{format}?q={term}&filter=tags")
    
    t_params = rest.rest_resources[0].rest_methods[0].request_parameters.select{ |p| p.param_style == "template" }
    assert_equal 2, t_params.size
    t_params.each { |p| assert %w{ api-v format }.include?(p.name) }
    
    q_params = rest.rest_resources[0].rest_methods[0].request_parameters.select{ |p| p.param_style == "query" }
    assert_equal 1, q_params.size
    assert_equal "q", q_params[0].name
    
    assert_equal "/{api-v}/search.{format}?filter=tags", rest.rest_resources[0].path

    rest.service.destroy
  end
  
  def test_add_parameters
    rest = create_rest_service(:endpoints => "/search?q={term}")
    method = rest.rest_resources[0].rest_methods[0]
        
    method.add_parameters("update=true", nil)
    assert_equal 1, method.request_parameters.size # should not add for nil user
    
    method.add_parameters("", Factory(:user))
    assert_equal 1, method.request_parameters.size # params size does not change
    
    method.add_parameters("xml=false !", Factory(:user))
    assert_equal 2, method.request_parameters.size # should increase by 1
    
    method.add_parameters("name=john-doe \n update=true \n name ! \n alias={jadefox} !", Factory(:user))
    assert_equal 5, method.request_parameters.size # should increase by 3

    rest.service.destroy
  end
  
  def test_add_representations
    user = Factory.create(:user)
    
    rest = create_rest_service(:endpoints => "put /workflow.xml")
    method = rest.rest_resources[0].rest_methods[0]
        
    assert method.rest_method_representations.empty?
    
    method.add_representations("application/xml", nil)
    assert method.rest_method_representations.empty? # should not add for nil user
    
    method.add_representations("xml", user)
    assert method.rest_method_representations.empty? # should not add
    
    method.add_representations("application/xml \n application/rdf", user, :http_cycle => "request")
    assert_equal 1, method.request_representations(true).size # should add new representations
    assert_equal 0, method.response_representations(true).size

    method.add_representations("application/xml", user, :http_cycle => "response")
    assert_equal 1, method.response_representations(true).size # should add new representations
    assert_equal 1, method.request_representations(true).size

    rest.service.destroy
  end
  
  def test_update_resource_path
    submitter = Factory.create(:user)
    rest = create_rest_service(:endpoints => "put /{db}/{id}", :submitter => submitter)
    
    method = rest.rest_resources[0].rest_methods[0]
    
    assert_not_nil = method.update_resource_path("", submitter) # error message returned
    assert_not_nil = method.update_resource_path("/{db}/{id}", submitter) # error message returned
    assert_not_nil = method.update_resource_path("/{db}/{id}?format={x}", submitter) # error message returned
    
    assert_nil = method.update_resource_path("/{db}/{id}.{format}?style=raw", submitter) # changed successfully

    rest.service.destroy
  end

  def test_sort
    rest = create_rest_service(:endpoints => "delete /{id} \n put /{id} \n post /{id} \n /{id} \n ", :submitter => Factory(:user))
    methods = rest.rest_resources[0].rest_methods.sort
    
    assert_equal methods[0].method_type, "GET"
    assert_equal methods[1].method_type, "PUT"
    assert_equal methods[2].method_type, "POST"
    assert_equal methods[3].method_type, "DELETE"

    rest.service.destroy
  end
end
