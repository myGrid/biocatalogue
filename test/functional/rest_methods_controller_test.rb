require 'test_helper'

class RestMethodsControllerTest < ActionController::TestCase
  def test_get_without_authentication
    get :update_resource_path
    assert_redirected_to :login
    
    get :edit_resource_path_popup
    assert_redirected_to :login
    
    get :update_endpoint_name
    assert_redirected_to :login
    
    get :edit_endpoint_name_popup
    assert_redirected_to :login
    
    get :remove_endpoint_name
    assert_redirected_to :login
    
    get :inline_add_endpoint_name
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
    post :inline_add_endpoint_name, :endpoint_name => "  \r\n ",
                                    :id => method.id,
                                    :partial => "endpoint_name"

    method = @rest.rest_resources[0].rest_methods(true)[0]
    assert method.endpoint_name.blank?
    
    # name changes
    post :inline_add_endpoint_name, :endpoint_name => "name",
                                    :id => method.id,
                                    :partial => "endpoint_name"

    method = @rest.rest_resources[0].rest_methods(true)[0]
    assert_equal "name", method.endpoint_name

    # no name change
    post :inline_add_endpoint_name, :endpoint_name => "  \r\n ",
                                    :id => method.id,
                                    :partial => "endpoint_name"

    method = @rest.rest_resources[0].rest_methods(true)[0]
    assert_equal "name", method.endpoint_name

    @rest.destroy
  end
  
  def test_remove_endpoint_name
    method = login_and_return_first_method("/{id}")
    
    method.endpoint_name = "some name"
    method.save!
    
    assert method.endpoint_name == "some name"
    
    post :remove_endpoint_name, :id => method.id

    method = @rest.rest_resources[0].rest_methods(true)[0]
    assert method.endpoint_name.blank?
    assert_redirected_to method
    
    @rest.destroy
  end
  
  def test_update_endpoint_name
    method = login_and_return_first_method("/{id}")
    
    method.endpoint_name = "name"
    method.save!
    
    # no name change
    post :update_endpoint_name, :new_name => "name",
                                :id => method.id

    method = @rest.rest_resources[0].rest_methods(true)[0]
    assert_equal "name", method.endpoint_name
    assert_redirected_to method
    
    # name changes
    post :update_endpoint_name, :new_name => "name 2",
                                :id => method.id

    method = @rest.rest_resources[0].rest_methods(true)[0]
    assert_equal "name 2", method.endpoint_name

    # no name change
    post :update_endpoint_name, :new_name => "  \r\n ",
                                :id => method.id

    method = @rest.rest_resources[0].rest_methods(true)[0]
    assert_equal "name 2", method.endpoint_name

    @rest.destroy
  end

  def test_update_resource_path
    method = login_and_return_first_method("/{id}")
    
    @rest.destroy
  end
  
private
  
  def login_and_return_first_method(endpoint="")
    user = Factory.create(:user)
    do_login_for_functional_test(user)
    
    @rest = create_rest_service(:submitter => user, :endpoints => endpoint)
    return @rest.rest_resources[0].rest_methods[0]
  end

end
