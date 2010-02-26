require 'test_helper'

class UserTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  def test_user_created
    assert Factory.create(:user)
  end
end
