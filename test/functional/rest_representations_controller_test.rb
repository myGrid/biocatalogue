require 'test_helper'

class RestRepresentationsControllerTest < ActionController::TestCase
  def test_get_page_without_authentication
    get :new_popup
    assert_redirected_to :login
    
    get :add_new_representations
    assert_redirected_to :login
  end
  
  def test_get_new_popup
    do_login_for_functional_test
    
    rest = create_rest_service(:endpoints => "/{id}")
    
    get :new_popup, :rest_method_id => rest.rest_resources[0].rest_methods[0].id
    assert !flash[:error].blank?
    
    rest.service.destroy
  end
    
  def test_unauthorised_add_new_representations
    method = login_and_return_first_method("/{id}")
    rep = "application/xml"
    
    do_login_for_functional_test # login as a different user
    
    assert_difference('RestRepresentation.count', 0) do
      post :add_new_representations, :rest_method_id => method.id,
                                     :rest_representations => rep,
                                     :http_cycle => "request"
    end

    @rest.service.destroy
  end

  def test_add_new_representations
    method = login_and_return_first_method("/{id}")
    rep = "application/xml"

    assert_difference('RestRepresentation.count', 2) do
      post :add_new_representations, :rest_method_id => method.id,
                                     :rest_representations => rep,
                                     :http_cycle => "response"
                         
      post :add_new_representations, :rest_method_id => method.id,
                                     :rest_representations => rep,
                                     :http_cycle => "request"
    end

    @rest.service.destroy    
  end     
end
