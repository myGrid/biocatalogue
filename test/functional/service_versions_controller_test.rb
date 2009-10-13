require 'test_helper'

class ServiceVersionsControllerTest < ActionController::TestCase
  def test_should_get_index
#    get :index
    assert_response :success
#    assert_not_nil assigns(:service_versions)
  end

  def test_should_get_new
#    get :new
    assert_response :success
  end

  def test_should_create_service_version
#    assert_difference('ServiceVersion.count') do
#      post :create, :service_version => { }
#    end

#    assert_redirected_to service_version_path(assigns(:service_version))
  end

  def test_should_show_service_version
#    get :show, :id => service_versions(:one).id
    assert_response :success
  end

  def test_should_get_edit
#    get :edit, :id => service_versions(:one).id
    assert_response :success
  end

  def test_should_update_service_version
#    put :update, :id => service_versions(:one).id, :service_version => { }
#    assert_redirected_to service_version_path(assigns(:service_version))
  end

  def test_should_destroy_service_version
#    assert_difference('ServiceVersion.count', -1) do
#      delete :destroy, :id => service_versions(:one).id
#    end

#    assert_redirected_to service_versions_path
  end
end
