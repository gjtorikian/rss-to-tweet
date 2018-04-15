require File.expand_path '../test_helper.rb', __FILE__

class BasicTest < MiniTest::Unit::TestCase

  include Rack::Test::Methods

  def app
    RssToTweet
  end

  def test_get_root

  end

end
