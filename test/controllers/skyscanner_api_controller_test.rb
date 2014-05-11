require 'test_helper'

class SkyscannerApiControllerTest < ActionController::TestCase
  test "should get demo" do
    get :demo
    assert_response :success
  end

  test "should get cheapest_quotes" do
    get :cheapest_quotes
    assert_response :success
  end

end
