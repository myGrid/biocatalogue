require 'test_helper'

class RestParametersControllerTest < ActionController::TestCase
  def test_get_without_authentication
    get :make_optional_or_mandatory, :id => rest_parameters(:test_rest_parameter).id
    assert_redirected_to :login
    
    get :add_new_parameters
    assert_redirected_to :login
    
    get :new_popup
    assert_redirected_to :login
    
    get :update_constrained_options, :id => rest_parameters(:test_rest_parameter).id
    assert_redirected_to :login
    
    get :edit_constrained_options_popup, :id => rest_parameters(:test_rest_parameter).id
    assert_redirected_to :login
    
    get :inline_add_default_value, :id => rest_parameters(:test_rest_parameter).id
    assert_redirected_to :login
    
    get :edit_default_value_popup, :id => rest_parameters(:test_rest_parameter).id
    assert_redirected_to :login

    get :update_default_value, :id => rest_parameters(:test_rest_parameter).id
    assert_redirected_to :login
  end

  def test_add_new_parameters
    rest = login_and_create_service_with_endpoints("/{id}")
    method = rest.rest_resources[0].rest_methods[0]
    
    assert_difference('RestParameter.count', 0) do # adding parameter that exists
      post :add_new_parameters, :rest_method_id => method.id,
                                :rest_parameters => "id"
    end
    
    assert_difference('RestParameter.count', 1) do
      post :add_new_parameters, :rest_method_id => method.id,
                                :rest_parameters => "x"
    end
    
    rest.service.destroy
  end

  def test_unauthorised_add_new_parameters
    rest = login_and_create_service_with_endpoints("/{id}")
    method = rest.rest_resources[0].rest_methods[0]
    
    do_login_for_functional_test
    assert_difference('RestParameter.count', 0) do
      post :add_new_parameters, :rest_method_id => method.id, 
                                :rest_parameters => "x"
    end
    
    rest.service.destroy
  end
  
  def test_add_multiple_parameters
    rest = login_and_create_service_with_endpoints("/workflow.xml")
    method = rest.rest_resources[0].rest_methods[0]
    
    assert_difference('RestParameter.count', 3) do # adding multiple params
      post :add_new_parameters, :rest_method_id => method.id,
                                :rest_parameters => "x={x} !\ny !\n z=z"
    end
    
    rest.service.destroy
  end
  
  def globalise_and_localise_parameter # TEST DISABLED
    rest = login_and_create_service_with_endpoints("?id={x}")
    method = rest.rest_resources[0].rest_methods[0]
    param = method.request_parameters[0]
    param_name = param.name
    
    # make local
    assert_difference('RestParameter.count', 0) do
      put :localise_globalise_parameter, :id => param.id,
                                         :rest_method_id => method.id,
                                         :make_local => true
    end
    
    assert_equal RestParameter.last.name, param_name
    assert !RestParameter.last.is_global
    
    # make global
    assert_difference('RestParameter.count', 0) do
      put :localise_globalise_parameter, :id => RestParameter.last.id,
                                         :rest_method_id => method.id,
                                         :make_local => false
    end

    assert_equal RestParameter.last.name, param_name
    assert RestParameter.last.is_global

    rest.service.destroy
  end
    
  def test_make_optional_or_mandatory
    rest = login_and_create_service_with_endpoints("/{id}")
    method = rest.rest_resources[0].rest_methods[0]
    param = method.request_parameters[0]
    
    assert param.required
    
    put :make_optional_or_mandatory, :id => param.id,
                                     :rest_method_id => method.id
    
    assert !method.request_parameters(true)[0].required

    rest.service.destroy
  end
  
  def test_constrained_options
    rest = login_and_create_service_with_endpoints("/{id}")
    method = rest.rest_resources[0].rest_methods[0]
    param = method.request_parameters[0]

    assert param.constrained_options.empty?
    assert !param.constrained
    
    # add constraint
    assert_difference('RestParameter.last.constrained_options.size', 3) do
      put :update_constrained_options, :new_constrained_options => "x\ny\nz",
                                       :id => param.id,
                                       :rest_method_id => method.id,
                                       :partial => "constrained_options"
    end
    
    param = method.request_parameters(true)[0]
    assert_equal "x", param.constrained_options[0]
    assert_equal param.constrained_options.size, 3
    assert param.constrained
    
    # remove constraint
    put :remove_constrained_options, :id => param.id,
                                     :rest_method_id => method.id

    param = method.request_parameters(true)[0]    
    assert !param.constrained
    assert param.constrained_options.empty?

    rest.service.destroy
  end
  
  def test_default_value
    rest = login_and_create_service_with_endpoints("/{id}")
    method = rest.rest_resources[0].rest_methods[0]
    param = method.request_parameters[0]

    assert param.default_value.blank?
    
    # add default_value
    put :inline_add_default_value, :default_value => "value",
                                   :id => param.id,
                                   :rest_method_id => method.id,
                                   :partial => "default_value"
    
    param = method.request_parameters(true)[0]
    assert_equal "value", param.default_value
    
    # update default_value
    put :update_default_value, :new_value => "new value",
                               :old_value => param.default_value,
                               :id => param.id,
                               :rest_method_id => method.id
    
    param = method.request_parameters(true)[0]
    assert_equal "new+value", param.default_value
    
    # remove default_value
    put :remove_default_value, :id => param.id,
                               :rest_method_id => method.id

    param = method.request_parameters(true)[0]    
    assert param.default_value.blank?

    rest.service.destroy
  end
  
private
  
  def login_and_create_service_with_endpoints(endpoint="")
    user = Factory.create(:user)
    do_login_for_functional_test(user)
    
    return create_rest_service(:submitter => user, :endpoints => endpoint)
  end
end
