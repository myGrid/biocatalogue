require 'test_helper'

class ContentBlobTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  def test_truth
    assert true
  end
  
  def setup
    @content_blob = Factory(:content_blob)
  end
  
  test "should not be valid without data" do
    content_blob = @content_blob
    assert content_blob.valid?
    content_blob.data = nil
    assert !content_blob.valid?, "content blob contains no data"
  end
end
