require File.dirname(__FILE__) + '/test_helper.rb'
require 'favourites_controller'
require 'action_controller/test_process'

# Manually override the rescue_action in the controller to raise the exception back.
class FavouritesController; def rescue_action(e) raise e end; end

class FavouritesControllerTest < ActionController::TestCase
  def setup
    ActionController::Routing::Routes.draw do |map|
      Favourites.map_routes(map)
    end
    
    @controller = FavouritesController.new
    @request = ActionController::TestRequest.new
    @response = ActionController::TestResponse.new
  end
  
  def test_current_user_is available
    assert_not_nil @controller.current_user
  end

  def test_index
    get :index
    assert_response :success
  end
end
