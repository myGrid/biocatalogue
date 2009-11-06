require 'test_helper'

class ServicesControllerTest < ActionController::TestCase
  def test_should_get_index
    get :index
    assert_response :success
    assert_not_nil assigns(:services)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end

  def test_should_not_create_service
    post :create, :service => {:name => "MyString", :submitter_id => 1, 
        :submitter_type => "User", :unique_code => "MyString"}
    assert_equal flash[:error], 'Select the type of service you would like to submit first'
  end

  def test_should_show_service
    get :show, :id => Service.first.id
    assert_response :success
  end

#  def test_should_get_edit
#    get :edit, :id => 1
#    assert_response :success
#  end

#  def test_should_update_service
#    put :update, :id => 1, :service => {:name => "MyString1" }
#    assert_not_equal :service.name, "MyString"
#    assert_redirected_to service_path(assigns(:service))
#  end

#  def test_should_destroy_service
#    assert_difference('Service.count', -1) do
#      delete :destroy, :id => 1
#    end
#
#    assert_redirected_to services_path
#  end
end
