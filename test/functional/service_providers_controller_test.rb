require 'test_helper'

class ServiceProvidersControllerTest < ActionController::TestCase
  def test_should_get_index
#    get :index
    assert_response :success
#    assert_not_nil assigns(:service_providers)
  end

  def test_should_get_new
#    get :new
    assert_response :success
  end

  def test_should_create_service_provider
#    assert_difference('ServiceProvider.count') do
#      post :create, :service_provider => { }
#    end

#    assert_redirected_to service_provider_path(assigns(:service_provider))
  end

  def test_should_show_service_provider
#    get :show, :id => service_providers(:one).id
    assert_response :success
  end

  def test_should_get_edit
#    get :edit, :id => service_providers(:one).id
    assert_response :success
  end

  def test_should_update_service_provider
#    put :update, :id => service_providers(:one).id, :service_provider => { }
#    assert_redirected_to service_provider_path(assigns(:service_provider))
  end

  def test_should_destroy_service_provider
#    assert_difference('ServiceProvider.count', -1) do
#      delete :destroy, :id => service_providers(:one).id
#    end

#    assert_redirected_to service_providers_path
  end
end
