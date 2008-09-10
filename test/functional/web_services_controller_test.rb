require 'test_helper'

class WebServicesControllerTest < ActionController::TestCase
  def test_should_get_index
    get :index
    assert_response :success
    assert_not_nil assigns(:web_services)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end

  def test_should_create_web_service
    assert_difference('WebService.count') do
      post :create, :web_service => { }
    end

    assert_redirected_to web_service_path(assigns(:web_service))
  end

  def test_should_show_web_service
    get :show, :id => web_services(:one).id
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => web_services(:one).id
    assert_response :success
  end

  def test_should_update_web_service
    put :update, :id => web_services(:one).id, :web_service => { }
    assert_redirected_to web_service_path(assigns(:web_service))
  end

  def test_should_destroy_web_service
    assert_difference('WebService.count', -1) do
      delete :destroy, :id => web_services(:one).id
    end

    assert_redirected_to web_services_path
  end
end
