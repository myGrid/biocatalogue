require 'test_helper'

class ServiceDeploymentsControllerTest < ActionController::TestCase
  def test_should_get_index
    get :index
    assert_response :success
    assert_not_nil assigns(:service_deployments)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end

  def test_should_create_service_deployment
    assert_difference('ServiceDeployment.count') do
      post :create, :service_deployment => { }
    end

    assert_redirected_to service_deployment_path(assigns(:service_deployment))
  end

  def test_should_show_service_deployment
    get :show, :id => service_deployments(:one).id
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => service_deployments(:one).id
    assert_response :success
  end

  def test_should_update_service_deployment
    put :update, :id => service_deployments(:one).id, :service_deployment => { }
    assert_redirected_to service_deployment_path(assigns(:service_deployment))
  end

  def test_should_destroy_service_deployment
    assert_difference('ServiceDeployment.count', -1) do
      delete :destroy, :id => service_deployments(:one).id
    end

    assert_redirected_to service_deployments_path
  end
end
