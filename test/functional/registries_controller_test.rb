require 'test_helper'

class RegistriesControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:registries)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create registry" do
    assert_difference('Registry.count') do
      post :create, :registry => { }
    end

    assert_redirected_to registry_path(assigns(:registry))
  end

  test "should show registry" do
    get :show, :id => registries(:one).id
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => registries(:one).id
    assert_response :success
  end

  test "should update registry" do
    put :update, :id => registries(:one).id, :registry => { }
    assert_redirected_to registry_path(assigns(:registry))
  end

  test "should destroy registry" do
    assert_difference('Registry.count', -1) do
      delete :destroy, :id => registries(:one).id
    end

    assert_redirected_to registries_path
  end
end
