require 'test_helper'

class SoapServicesControllerTest < ActionController::TestCase
  def test_should_get_index
    get :index
    assert_response :success
    assert_not_nil assigns(:soap_services)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end

  def test_should_create_soap_service
    assert_difference('SoapService.count') do
      post :create, :soap_service => { }
    end

    assert_redirected_to soap_service_path(assigns(:soap_service))
  end

  def test_should_show_soap_service
    get :show, :id => soap_services(:one).id
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => soap_services(:one).id
    assert_response :success
  end

  def test_should_update_soap_service
    put :update, :id => soap_services(:one).id, :soap_service => { }
    assert_redirected_to soap_service_path(assigns(:soap_service))
  end

  def test_should_destroy_soap_service
    assert_difference('SoapService.count', -1) do
      delete :destroy, :id => soap_services(:one).id
    end

    assert_redirected_to soap_services_path
  end
end
