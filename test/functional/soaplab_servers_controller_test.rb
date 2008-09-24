require 'test_helper'

class SoaplabServersControllerTest < ActionController::TestCase
  def test_should_get_index
    get :index
    assert_response :success
    assert_not_nil assigns(:soaplab_servers)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end

  def test_should_create_soaplab_server
    assert_difference('SoaplabServer.count') do
      post :create, :soaplab_server => { }
    end

    assert_redirected_to soaplab_server_path(assigns(:soaplab_server))
  end

  def test_should_show_soaplab_server
    get :show, :id => soaplab_servers(:one).id
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => soaplab_servers(:one).id
    assert_response :success
  end

  def test_should_update_soaplab_server
    put :update, :id => soaplab_servers(:one).id, :soaplab_server => { }
    assert_redirected_to soaplab_server_path(assigns(:soaplab_server))
  end

  def test_should_destroy_soaplab_server
    assert_difference('SoaplabServer.count', -1) do
      delete :destroy, :id => soaplab_servers(:one).id
    end

    assert_redirected_to soaplab_servers_path
  end
end
