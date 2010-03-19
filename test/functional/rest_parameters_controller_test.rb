require 'test_helper'

class RestParametersControllerTest < ActionController::TestCase
  test "get something without logging in" do
    get :make_optional_or_mandatory
    assert_redirected_to :login
    
    get :add_new_parameters
    assert_redirected_to :login
    
    get :localise_globalise_parameter
    assert_redirected_to :login

    get :new_popup
    assert_redirected_to :login
    
    get :remove_constraint
    assert_redirected_to :login
    
    get :inline_add_constraints
    assert_redirected_to :login

    get :edit_constraint_popup
    assert_redirected_to :login
    
    get :inline_add_default_value
    assert_redirected_to :login
    
    get :edit_default_value_popup
    assert_redirected_to :login

    get :update_default_value
    assert_redirected_to :login
  end
  test "add new parameters" do
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
  end
  
  test "add multiple parameters" do
    rest = login_and_create_service_with_endpoints("/workflow.xml")
    method = rest.rest_resources[0].rest_methods[0]
          
    assert_equal 0, RestParameter.count

    assert_difference('RestParameter.count', 3) do # adding multiple params
      post :add_new_parameters, :rest_method_id => method.id, 
                                :rest_parameters => "x={x} !\ny !\n z=z"
    end
  end
  
  test "globalise and localise parameter" do
    rest = login_and_create_service_with_endpoints("?id={x}")
    method = rest.rest_resources[0].rest_methods[0]
    param = method.request_parameters[0]
    param_name = param.name
    
    # make local
    assert_difference('RestParameter.count', 0) do
      post :localise_globalise_parameter, :id => param.id,
                                          :rest_method_id => method.id,
                                          :make_local => true
    end
    
    assert_equal RestParameter.last.name, param_name
    assert !RestParameter.last.is_global
    
    # make global
    assert_difference('RestParameter.count', 0) do
      post :localise_globalise_parameter, :id => RestParameter.last.id,
                                          :rest_method_id => method.id,
                                          :make_local => false
    end

    assert_equal RestParameter.last.name, param_name
    assert RestParameter.last.is_global
  end
  
  test "globalise and localise parameter on a shared parameter" do
    rest = login_and_create_service_with_endpoints("/{id} \n put /{id}?xml=true") # 'id' is the shared/common parameter
    method = rest.rest_resources[0].rest_methods[0]
    param = method.request_parameters[0]
    param_name = param.name
    
    assert param.is_global
    
    # make local
    assert_difference('RestParameter.count', 1) do
      post :localise_globalise_parameter, :id => param.id,
                                          :rest_method_id => method.id,
                                          :make_local => true
    end
    
    assert_equal RestParameter.last.name, param_name
    assert !RestParameter.last.is_global
    
    # make global
    assert_difference('RestParameter.count', -1) do
      post :localise_globalise_parameter, :id => RestParameter.last.id,
                                          :rest_method_id => method.id,
                                          :make_local => false
    end
    
    assert_equal RestParameter.last.name, param_name
    assert RestParameter.last.is_global
  end
  
  test "make optional or mandatory" do
    rest = login_and_create_service_with_endpoints("/{id}")
    method = rest.rest_resources[0].rest_methods[0]
    param = method.request_parameters[0]
    
    assert param.required
    
    post :make_optional_or_mandatory, :id => param.id,
                                      :rest_method_id => method.id
    
    assert !param.required
  end
  
  test "constraints" do
    rest = login_and_create_service_with_endpoints("/{id}")
    method = rest.rest_resources[0].rest_methods[0]

    assert RestParameter.last.constrained_options.empty?
    
    # add constraint
    assert_difference('RestParameter.last.constrained_options.size', 1) do
      post :inline_add_constraints, :constraint => "the constraint",
                                    :id => RestParameter.last.id,
                                    :rest_method_id => method.id,
                                    :partial => "constraints"
    end
    
    # update constraint
    post :update_constraint, :new_constraint => "new",
                             :id => RestParameter.last.id,
                             :rest_method_id => method.id

    assert_equal RestParameter.last.constrained_options[0], "new"
    
    # remove constraint
    post :remove_constraint, :constraint => "doesn't exist, so nothing will change",
                             :id => RestParameter.last.id,
                             :rest_method_id => method.id
    
    assert_equal RestParameter.last.constrained_options[0], "new"
    assert_equal RestParameter.last.constrained_options.size, 1
    
    post :remove_constraint, :constraint => "new",
                             :id => RestParameter.last.id,
                             :rest_method_id => method.id
    
    assert RestParameter.last.constrained_options.empty?
    
  end
  
  
  # ========================================
  
  
  private
  
  def login_and_create_service_with_endpoints(endpoint="")
    user = Factory.create(:user)
    do_login_for_functional_test(user)
    
    return create_rest_service(:submitter => user, :endpoints => endpoint)
  end
end
