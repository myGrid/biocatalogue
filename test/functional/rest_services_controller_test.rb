require 'test_helper'

class RestServicesControllerTest < ActionController::TestCase
#  test "should get index" do
#    get :index
#    assert_response :success
#    assert_not_nil assigns(:rest_services)
#  end

  test "should get new" do
#    get :new
    assert_response :success
  end

  test "should create rest_service" do
#    assert_difference('RestService.count') do
#      post :create, :rest_service => { }
#    end

#    assert_redirected_to rest_service_path(assigns(:rest_service))
  end

  test "should show rest_service" do
#    get :show, :id => rest_services(:one).id
    assert_response :success
  end

  test "should get edit" do
#    get :edit, :id => rest_services(:one).id
    assert_response :success
  end

  test "should update rest_service" do
#    put :update, :id => rest_services(:one).id, :rest_service => { }
#    assert_redirected_to rest_service_path(assigns(:rest_service))
  end

  test "should destroy rest_service" do
#    assert_difference('RestService.count', -1) do
#      delete :destroy, :id => rest_services(:one).id
#    end

#    assert_redirected_to rest_services_path
  end
end
