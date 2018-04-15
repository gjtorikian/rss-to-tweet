require File.expand_path '../test_helper.rb', __FILE__

class AppTest < MiniTest::Unit::TestCase

  include Rack::Test::Methods

  def app
    RssToTweet
  end

  def test_get_root
    get '/'
    assert last_response.ok?
    assert_equal 'This server is running!', last_response.body
  end

  def test_denies_bogus_origin
    post '/'
    assert_equal last_response.status, 404
  end

  def test_skips_empty_payload
    post '/rss-to-tweet', nil, { 'HTTP_X_HUB_SIGNATURE' => '123' }
    assert_equal last_response.status, 400
  end

  def test_skips_bogus_secret_from_github
    data = '{"data": "hello"}'.to_json
    with_env({ SECRET_TOKEN: '123' }) do
      post '/rss-to-tweet', data.to_json, { 'HTTP_X_HUB_SIGNATURE' => '123' }
    end
    assert_equal last_response.status, 401
  end

  def test_skips_non_page_build_event
    data = '{"data": "hello"}'.to_json
    with_env({ SECRET_TOKEN: '123' }) do
      post '/rss-to-tweet', data, { 'HTTP_X_HUB_SIGNATURE' => 'sha1=bfbdc0827fcba41ceea1ec6a6c189ed2522a3dc3' }
      assert_equal last_response.status, 202
      assert_equal last_response.body, 'Payload was not for a `page_build` event'
    end
  end

  def test_skips_unsuccessful_page_build_event
    data = load_fixture_text('unsuccessful_build.json')
    with_env({ SECRET_TOKEN: '123' }) do
      post '/rss-to-tweet', data, { 'HTTP_X_GITHUB_EVENT' => 'page_build', 'HTTP_X_HUB_SIGNATURE' => 'sha1=740f764aa02a2dbf5540f8f395762dc7b1938696' }
      assert_equal last_response.status, 202
      assert_equal last_response.body, 'Page build status was not `built`, it was `errored`, aborting'
    end
  end
end
