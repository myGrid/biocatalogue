require 'test_helper'

class RestMethodsControllerTest < ActionController::TestCase

  def test_get_without_authentication

    rest = create_rest_service(:endpoints => "/{id}")

    get :update_resource_path, :id => rest.rest_resources[0].rest_methods[0].id
    assert_redirected_to :login
    
    get :edit_resource_path_popup, :id => rest.rest_resources[0].rest_methods[0].id
    assert_redirected_to :login
    
    get :update, :id => rest.rest_resources[0].rest_methods[0].id
    assert_redirected_to :login
    
    get :edit_endpoint_name_popup, :id => rest.rest_resources[0].rest_methods[0].id
    assert_redirected_to :login
    
    get :remove_endpoint_name, :id => rest.rest_resources[0].rest_methods[0].id
    assert_redirected_to :login
    
    post :inline_add_endpoint_name, :id => rest.rest_resources[0].rest_methods[0].id
    assert_redirected_to :login
  end
  
  def test_show
    rest = create_rest_service(:endpoints => "/{id}")
    get :show, :id => rest.rest_resources[0].rest_methods[0].id
    assert :success
  end
  
  def test_inline_add_endpoint_name
    method = login_and_return_first_method("/{id}")
    
    assert method.endpoint_name.blank?

    # no name change
    put :inline_add_endpoint_name, :endpoint_name => "  \r\n ",
                                   :id => method.id,
                                   :partial => "endpoint_name"

    method = @rest.rest_resources[0].rest_methods(true)[0]
    assert method.endpoint_name.blank?
    
    # name changes
    put :inline_add_endpoint_name, :endpoint_name => "name",
                                   :id => method.id,
                                   :partial => "endpoint_name"

    method = @rest.rest_resources[0].rest_methods(true)[0]
    assert_equal "name", method.endpoint_name

    # no name change
    put :inline_add_endpoint_name, :endpoint_name => "  \r\n ",
                                   :id => method.id,
                                   :partial => "endpoint_name"

    method = @rest.rest_resources[0].rest_methods(true)[0]
    assert_equal "name", method.endpoint_name

    @rest.service.destroy
  end
  
  def test_remove_endpoint_name
    method = login_and_return_first_method("/{id}")
    
    method.endpoint_name = "some name"
    method.save!
    
    assert method.endpoint_name == "some name"
    
    put :remove_endpoint_name, :id => method.id

    method = @rest.rest_resources[0].rest_methods(true)[0]
    assert method.endpoint_name.blank?
    assert_redirected_to method
    
    @rest.service.destroy
  end
  
  def test_update
    method = login_and_return_first_method("/{id}")
    
    method.endpoint_name = "name"
    method.save!
    
    # no name change
    put :update, :new_name => "name",
                               :id => method.id

    method = @rest.rest_resources[0].rest_methods(true)[0]
    assert_equal "name", method.endpoint_name
    assert_redirected_to method
    
    # name changes
    put :update, :new_name => "name 2",
                               :id => method.id

    method = @rest.rest_resources[0].rest_methods(true)[0]
    assert_equal "name 2", method.endpoint_name

    # no name change
    put :update, :new_name => "  \r\n ",
                               :id => method.id

    method = @rest.rest_resources[0].rest_methods(true)[0]
    assert_equal "name 2", method.endpoint_name

    @rest.service.destroy
  end

  def test_update_resource_path
    method = login_and_return_first_method("/{id}")
    
    fails = [ '', '/{id}', '/q={q}' ]
    passes = [ '/{id}.{format}', '/workflow.xml' ]
    
    fails.each do |path|
      put :update_resource_path, :id => method.id,
                                 :new_path => path
                                 
      method = @rest.rest_resources(true)[0].rest_methods[0]
      assert_equal method.rest_resource.path, "/{id}"
    end

    passes.each do |path|
      put :update_resource_path, :id => method.id,
                                 :new_path => path
                                 
      method = @rest.rest_resources(true)[0].rest_methods[0]
      assert_equal method.rest_resource.path, path
      
      if path.include?('{') && path.include?('}')
        assert !method.request_parameters.select{ |p| p.param_style=='template'}.empty?
      else
        assert method.request_parameters.select{ |p| p.param_style=='template'}.empty?
      end
    end
    
    @rest.service.destroy
  end

end
